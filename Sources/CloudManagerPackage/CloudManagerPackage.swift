import Foundation
import CloudKit

public protocol CloudStorable {
    init?(from record: CKRecord)
    static func fromCKRecord(_ record: CKRecord) -> Self?
    func toCKRecord() -> CKRecord
}

public protocol Relatable: CloudStorable {
    var parentRef: CKRecord.Reference? { get set }
}


/**
 `CloudManager` é uma classe genérica projetada para simplificar o processo de interação com o CloudKit, permitindo operações CRUD (Criar, Ler, Atualizar e Deletar) em registros do iCloud.

 Para utilizar esta classe:

 1. **Conformidade com `CloudStorable`**:
    O tipo que você deseja salvar no CloudKit deve conformar com o protocolo `CloudStorable`. Isso garante que o tipo possa ser convertido para e de um `CKRecord`, que é o formato utilizado pelo CloudKit para armazenar e recuperar dados.

 2. **Inicialização**:
    Ao criar uma instância de `CloudManager`, a classe automaticamente se configura para usar o container padrão do CloudKit e o banco de dados privado associado a esse container.

 3. **Verificação do iCloud**:
    A classe verifica o status da conta iCloud do usuário para garantir que o iCloud está disponível e configurado corretamente.

 4. **Operações CRUD**:
    - **Criar**: Use o método `saveItem` para salvar um novo item no CloudKit.
    - **Ler**: Use o método `fetchItems` para buscar todos os itens do tipo especificado no CloudKit.
    - **Atualizar**: Use o método `updateItem` para atualizar um item existente no CloudKit.
    - **Deletar**: Use o método `deleteItem` para excluir um item do CloudKit.

 5. **Extensibilidade**:
    A classe é projetada para ser extensível. Se você precisar de funcionalidades adicionais ou comportamentos específicos, pode estender ou
     personalizar `CloudManager` conforme necessário. Por exemplo, se você quiser adicionar filtragem avançada ou ordenação durante a busca, pode adicionar métodos adicionais ou parâmetros para atender a esses requisitos.

 6. **Tratamento de Erros**:
     Todos os métodos que interagem com o CloudKit fornecem feedback através de closures de conclusão. Estes closures retornam um `Result` que pode ser um sucesso (com o tipo de dado esperado) ou uma falha (com um erro). Isso permite que você trate erros de maneira robusta e forneça feedback adequado ao usuário.

 7. **Performance e Otimização**:
     A classe utiliza `CKQueryOperation` para buscar registros, o que é eficiente e permite a busca de grandes conjuntos de dados de forma paginada. Se você tiver um grande volume de dados, considere implementar lógicas de paginação ou filtragem para otimizar as operações de busca.
 
 8. **Segurança**:
     Como `CloudManager` utiliza o banco de dados privado do CloudKit, os dados são específicos do usuário e não são compartilhados entre usuários. Isso garante que as informações do usuário permaneçam privadas e seguras.
 
 9. **Considerações Adicionais**:
     - Certifique-se de ter as permissões adequadas e de configurar o CloudKit corretamente no portal do desenvolvedor da Apple e no seu projeto.
     - Lembre-se de testar todas as operações em diferentes cenários para garantir a robustez e a confiabilidade da sua implementação.

 10. **Exemplo:**
    ```swift
    struct MyData: CloudStorable {
        // ... sua implementação aqui ...
    }

    let manager = CloudManager<MyData>()
    manager.fetchItems { result in
        // ... manipule os resultados aqui ...
    }
    ```

 - Observações:
    - Certifique-se de que o tipo que você está usando com `CloudManager` implemente todos os requisitos do protocolo `CloudStorable`.
    - A classe verifica automaticamente o status da conta iCloud do usuário. Se o iCloud não estiver disponível ou configurado, a propriedade `iCloudOk` será `false`.
    - Erros são retornados através de closures de conclusão, permitindo que você os manipule conforme necessário.

 - Requisitos:
    - iOS 15.0 ou superior.
    - Conformidade com o protocolo `CloudStorable` para os tipos que você deseja gerenciar com `CloudManager`.
*/
public class CloudManager<T: CloudStorable> {

    let container: CKContainer
    let dataBase: CKDatabase
    var iCloudOk : Bool = false
    var items: [T] = []
    
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
                self.iCloudOk.toggle()
                // Aqui você pode prosseguir com a autenticação ou outras operações do CloudKit
            case .noAccount:
                print("Nenhuma conta iCloud configurada")
                self.iCloudOk.toggle()
                // Aqui você pode pedir ao usuário para configurar uma conta iCloud nas configurações
            case .restricted:
                print("iCloud restrito")
                // Aqui você pode informar ao usuário que o iCloud está restrito e não pode ser acessado
            case .couldNotDetermine:
                print("Não foi possível determinar o status da conta iCloud")
                self.iCloudOk.toggle()
                // Aqui você pode mostrar uma mensagem de erro genérica
            case .temporarilyUnavailable:
                print("Teporariamente indisponivel")
                self.iCloudOk.toggle()
            @unknown default:
                print("Status da conta iCloud desconhecido")
                self.iCloudOk.toggle()
                // Aqui você pode lidar com casos desconhecidos, talvez mostrando uma mensagem de erro genérica
            }
        }
    }

    
    
    // CREATE
    public func saveItem(_ item: T, completion: @escaping (Result<T, Error>) -> Void) {
        dataBase.save(item.toCKRecord()) { returnedRecord, error in
            if let error = error {
                completion(.failure(error))
            } else if let record = returnedRecord, let item = T.fromCKRecord(record) {
                completion(.success(item))
            }
        }
    }
    
    // READ
    public func fetchItems(_ completion: @escaping (Result<[T], Error>) -> Void) {
        let predicate = NSPredicate(value: true)
        let query = CKQuery(recordType: String(describing: T.self), predicate: predicate)
        let queryOperation = CKQueryOperation(query: query)
        
        var fetchedItems: [T] = []
        
        queryOperation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                if let item = T.fromCKRecord(record) {
                    fetchedItems.append(item)
                }
            case .failure(let error):
                print("Error \(error)")
            }
        }
        
        queryOperation.queryResultBlock = { result in
            switch result {
            case .success(_):
                // Se você precisar continuar buscando com o cursor, pode fazê-lo aqui.
                // Por enquanto, vamos simplesmente retornar os itens buscados.
                completion(.success(fetchedItems))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        dataBase.add(queryOperation)
    }

    // UPDATE
    public func fetchItems(withPredicate predicate: NSPredicate? = nil, completion: @escaping (Result<[T], Error>) -> Void) {
        let query = CKQuery(recordType: T.defaultRecordType(), predicate: predicate ?? T.defaultPredicate())
        let queryOperation = CKQueryOperation(query: query)
        
        var fetchedItems: [T] = []
        
        queryOperation.recordMatchedBlock = { (returnedRecordID, returnedResult) in
            switch returnedResult {
            case .success(let record):
                if let item = T.fromCKRecord(record) {
                    fetchedItems.append(item)
                }
            case .failure(let error):
                print("Error \(error)")
            }
        }
        
        queryOperation.queryResultBlock = { result in
            switch result {
            case .success(_):
                // Se você precisar continuar buscando com o cursor, pode fazê-lo aqui.
                // Por enquanto, vamos simplesmente retornar os itens buscados.
                completion(.success(fetchedItems))
            case .failure(let error):
                completion(.failure(error))
            }
        }
        
        dataBase.add(queryOperation)
    }
    
    // DELETE
    public func deleteItem(_ item: T, completion: @escaping (Result<Void, Error>) -> Void) {
        let predicate = NSPredicate(format: "TRUEPREDICATE") // Consulta de verdade sempre retorna todos os registros
        
        fetchItems(withPredicate: predicate) { [self] result in
            switch result {
            case .success(let fetchedItems):
                if let existingItem = fetchedItems.first(where: { $0.isSameAs(item) }) {
                    dataBase.delete(withRecordID: existingItem.toCKRecord().recordID) { _, error in
                        if let error = error {
                            completion(.failure(error))
                        } else {
                            completion(.success(()))
                        }
                    }
                } else {
                    completion(.failure(NSError(domain: "CloudManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Item not found"])))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    public func saveParentWithChildren<Child: Relatable>(parent: T, children: [Child], completion: @escaping (Result<Void, Error>) -> Void) {
        saveItem(parent) { result in
            switch result {
            case .success(let savedParent):
                let parentReference = CKRecord.Reference(recordID: savedParent.toCKRecord().recordID, action: .deleteSelf)
                
                let updatedChildren = children.map { child -> Child in
                    var childCopy = child
                    childCopy.parentRef = parentReference
                    return childCopy
                }
                
                let childCloudManager = CloudManager<Child>()
                let group = DispatchGroup()
                for child in updatedChildren {
                    group.enter()
                    childCloudManager.saveItem(child) { _ in
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(()))
                }
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    ///On cascade
//    public func saveParentWithChildrenInCascade<Child: Relatable>(parent: T, children: [Child], completion: @escaping (Result<Void, Error>) -> Void) {
//        saveItem(parent) { result in
//            switch result {
//            case .success(let savedParent):
//                let parentReference = CKRecord.Reference(recordID: savedParent.toCKRecord().recordID, action: .deleteSelf)
//
//                let updatedChildren = children.map { child -> Child in
//                    var childCopy = child
//                    childCopy.parentRef = parentReference
//                    return childCopy
//                }
//
//                let childCloudManager = CloudManager<Child>()
//                let group = DispatchGroup()
//
//                for child in updatedChildren {
//                    group.enter()
//                    childCloudManager.saveItem(child) { childResult in
//                        switch childResult {
//                        case .success(let savedChild):
//                            // Aqui, você pode chamar recursivamente a função para salvar os "SubChildren" do "Child", se houver.
//                            // Por exemplo:
//                            let subChildCloudManager = CloudManager<SubChild>()
//                            subChildCloudManager.saveParentWithChildrenInCascade(parent: savedChild, children: savedChild.subChildren) { _ in
//                                group.leave()
//                            }
//                            group.leave()
//                        case .failure(_):
//                            group.leave()
//                        }
//                    }
//                }
//
//                group.notify(queue: .main) {
//                    completion(.success(()))
//                }
//
//            case .failure(let error):
//                completion(.failure(error))
//            }
//        }
//    }

        // Recuperar relação de um para muitos
    public func fetchChildrenForParent<Child: Relatable>(parent: T, completion: @escaping (Result<[Child], Error>) -> Void) {
        let predicate = NSPredicate(format: "parentRef == %@", parent.toCKRecord().recordID)
        let childCloudManager = CloudManager<Child>()
        childCloudManager.fetchItems(withPredicate: predicate, completion: completion)
    }
}



public extension CloudStorable {
    static func defaultRecordType() -> String {
            return String(describing: Self.self)
        }
        
    static func defaultPredicate() -> NSPredicate {
        return NSPredicate(value: true)
    }
        
    func isSameAs(_ other: Self) -> Bool {
        
        return false
    }
    
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: String(describing: Self.self))
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let key = child.label {
                switch child.value {
                case let value as CloudStorable:
                    // Se o valor é CloudStorable, salve-o como um CKRecord separado e adicione uma referência
                    let childRecord = value.toCKRecord()
                    let reference = CKRecord.Reference(record: childRecord, action: .deleteSelf)
                    record.setValue(reference, forKey: key)
                    
                case let valueArray as [CloudStorable]:
                    // Se o valor é uma lista de CloudStorable, salve cada item como um CKRecord e adicione uma lista de referências
                    let references = valueArray.map { item -> CKRecord.Reference in
                        let itemRecord = item.toCKRecord()
                        return CKRecord.Reference(record: itemRecord, action: .deleteSelf)
                    }
                    record.setValue(references, forKey: key)
                    
                default:
                    // Para outros tipos de valores, tente salvar diretamente
                    record.setValue(child.value, forKey: key)
                }
            }
        }
        
        return record
    }


    static func fromCKRecord(_ record: CKRecord) -> Self? {
        var initializers: [String: Any] = [:]

        let mirror = Mirror(reflecting: Self.self)
        for child in mirror.children {
            if let key = child.label {
                if let reference = record[key] as? CKRecord.Reference {
                    // Se o valor é uma referência, busque o CKRecord associado
                    let semaphore = DispatchSemaphore(value: 0)
                    let database = CKContainer.default().privateCloudDatabase
                    database.fetch(withRecordID: reference.recordID) { fetchedRecord, error in
                        if let fetchedRecord = fetchedRecord {
                            let itemType = child.value as? CloudStorable.Type
                            if let item = itemType?.fromCKRecord(fetchedRecord) {
                                initializers[key] = item
                            }
                        }
                        semaphore.signal()
                    }
                    semaphore.wait()
                    
                } else if let references = record[key] as? [CKRecord.Reference] {
                    // Se o valor é uma lista de referências, busque todos os CKRecords associados
                    var items: [CloudStorable] = []
                    let group = DispatchGroup()
                    for reference in references {
                        group.enter()
                        let database = CKContainer.default().privateCloudDatabase
                        database.fetch(withRecordID: reference.recordID) { fetchedRecord, error in
                            if let fetchedRecord = fetchedRecord {
                                let itemType = child.value as? CloudStorable.Type
                                if let item = itemType?.fromCKRecord(fetchedRecord) {
                                    items.append(item)
                                }
                            }
                            group.leave()
                        }
                    }
                    group.wait()
                    initializers[key] = items
                    
                } else {
                    // Para outros tipos de valores, tente recuperar diretamente
                    initializers[key] = record[key]
                }
            }
        }

        return Self.init(from: record)
    }
    
    func toCKAsset(from data: Data, withKey key: String) -> CKAsset? {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        
        do {
            try data.write(to: fileURL)
            return CKAsset(fileURL: fileURL)
        } catch {
            print("Erro ao converter dados para CKAsset: \(error.localizedDescription)")
            return nil
        }
    }

    func data(from asset: CKAsset?) -> Data? {
        guard let asset = asset else { return nil }
        do {
            let data = try Data(contentsOf: asset.fileURL!)
            return data
        } catch {
            print("Erro ao converter CKAsset para dados: \(error.localizedDescription)")
            return nil
        }
    }
    
    static func data(from asset: CKAsset?) -> Data? {  // Faça este método estático
        guard let asset = asset else { return nil }
        do {
            let data = try Data(contentsOf: asset.fileURL!)
            return data
        } catch {
            print("Erro ao converter CKAsset para dados: \(error.localizedDescription)")
            return nil
        }
    }
    
    
}

