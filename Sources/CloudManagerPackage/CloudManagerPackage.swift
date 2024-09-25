import Foundation
import CloudKit

public protocol CloudStorable {
    static func fromCKRecord(_ record: CKRecord) -> Self?
    func toCKRecord() -> CKRecord
    func isSameAs(_ other: Self) -> Bool
}

public protocol Relatable: CloudStorable {
    var parentRef: CKRecord.Reference? { get set }
}

/**
 `CloudManager` é uma classe genérica projetada para simplificar o processo de interação com o CloudKit, permitindo operações CRUD (Criar, Ler, Atualizar e Deletar) em registros do iCloud.

 **Como usar:**

 - Certifique-se de que seu tipo genérico `T` conforma com `CloudStorable` e implementa corretamente os métodos necessários.
 - Utilize os métodos `saveItem`, `fetchItems`, `updateItem` e `deleteItem` para gerenciar seus registros no CloudKit.
 */
public class CloudManager<T: CloudStorable> {

    let container: CKContainer
    let dataBase: CKDatabase
    var iCloudOk: Bool = false

    public init() {
        container = CKContainer.default()
        dataBase = container.privateCloudDatabase
        checkiCloudAccountStatus()
    }

    func checkiCloudAccountStatus() {
        let container = CKContainer.default()
        container.accountStatus { (accountStatus, error) in
            if let error = error {
                print("Erro ao obter o status da conta iCloud: \(error.localizedDescription)")
                return
            }
            switch accountStatus {
            case .available:
                print("iCloud disponível")
                self.iCloudOk = true
            case .noAccount:
                print("Nenhuma conta iCloud configurada")
                self.iCloudOk = false
            case .restricted:
                print("iCloud restrito")
                self.iCloudOk = false
            case .couldNotDetermine:
                print("Não foi possível determinar o status da conta iCloud")
                self.iCloudOk = false
            case .temporarilyUnavailable:
                print("Temporariamente indisponível")
                self.iCloudOk = false
            @unknown default:
                print("Status da conta iCloud desconhecido")
                self.iCloudOk = false
            }
        }
    }

    // CREATE
    public func saveItem(_ item: T, completion: @escaping (Result<T, Error>) -> Void) {
        let record = item.toCKRecord()
        dataBase.save(record) { returnedRecord, error in
            if let error = error {
                completion(.failure(error))
            } else if let returnedRecord = returnedRecord, let savedItem = T.fromCKRecord(returnedRecord) {
                completion(.success(savedItem))
            } else {
                let unknownError = NSError(domain: "CloudManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Erro desconhecido ao salvar o item."])
                completion(.failure(unknownError))
            }
        }
    }

    // READ
    public func fetchItems(withPredicate predicate: NSPredicate = NSPredicate(value: true), completion: @escaping (Result<[T], Error>) -> Void) {
        let recordType = String(describing: T.self)
        let query = CKQuery(recordType: recordType, predicate: predicate)
        let operation = CKQueryOperation(query: query)
        var items: [T] = []

        operation.recordFetchedBlock = { record in
            if let item = T.fromCKRecord(record) {
                items.append(item)
            }
        }

        operation.queryCompletionBlock = { cursor, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(items))
            }
        }

        dataBase.add(operation)
    }

    // UPDATE
    public func updateItem(_ item: T, completion: @escaping (Result<T, Error>) -> Void) {
        // No CloudKit, salvar um registro com o mesmo recordID atualiza o registro existente.
        saveItem(item, completion: completion)
    }

    // DELETE
    public func deleteItem(_ item: T, completion: @escaping (Result<Void, Error>) -> Void) {
        let recordID = item.toCKRecord().recordID
        dataBase.delete(withRecordID: recordID) { deletedRecordID, error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }

    // Salvar um pai com seus filhos
    public func saveParentWithChildren<Child: Relatable>(parent: T, children: [Child], completion: @escaping (Result<Void, Error>) -> Void) {
        saveItem(parent) { parentResult in
            switch parentResult {
            case .success(let savedParent):
                let parentRecordID = savedParent.toCKRecord().recordID
                let parentReference = CKRecord.Reference(recordID: parentRecordID, action: .none)

                let updatedChildren = children.map { child -> Child in
                    var mutableChild = child
                    mutableChild.parentRef = parentReference
                    return mutableChild
                }

                let childManager = CloudManager<Child>()
                let dispatchGroup = DispatchGroup()
                var saveError: Error?

                for child in updatedChildren {
                    dispatchGroup.enter()
                    childManager.saveItem(child) { childResult in
                        if case .failure(let error) = childResult {
                            saveError = error
                        }
                        dispatchGroup.leave()
                    }
                }

                dispatchGroup.notify(queue: .main) {
                    if let error = saveError {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }

            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    // Recuperar filhos de um pai
    public func fetchChildrenForParent<Child: Relatable>(parent: T, completion: @escaping (Result<[Child], Error>) -> Void) {
        let parentRecordID = parent.toCKRecord().recordID
        let predicate = NSPredicate(format: "parentRef == %@", parentRecordID)
        let childManager = CloudManager<Child>()
        childManager.fetchItems(withPredicate: predicate, completion: completion)
    }
}

