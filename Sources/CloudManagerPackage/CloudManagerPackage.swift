import Foundation
import CloudKit

public protocol CloudStorable {
    init?(from record: CKRecord)
    static func fromCKRecord(_ record: CKRecord) -> Self?
    func toCKRecord() -> CKRecord
    var recordID: CKRecord.ID? { get }

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
    public func updateItem(_ item: T, completion: @escaping (Result<T, Error>) -> Void) {
        guard let recordID = item.recordID else {
            completion(.failure(NSError(domain: "CloudManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Item does not have a recordID"])))
            return
        }
        
        dataBase.fetch(withRecordID: recordID) { (record, error) in
            if let error = error {
                completion(.failure(error))
            } else if let record = record {
                let updatedRecord = item.toCKRecord()
                for key in updatedRecord.allKeys() {
                    record.setValue(updatedRecord[key], forKey: key)
                }
                
                self.dataBase.save(record) { (savedRecord, saveError) in
                    if let saveError = saveError {
                        completion(.failure(saveError))
                    } else if let savedRecord = savedRecord, let updatedItem = T.fromCKRecord(savedRecord) {
                        completion(.success(updatedItem))
                    }
                }
            }
        }
    }

    
    // DELETE
    public func deleteItem(_ item: T, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let recordID = item.recordID else {
            completion(.failure(NSError(domain: "CloudManagerError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Item does not have a recordID"])))
            return
        }
        
        dataBase.delete(withRecordID: recordID) { (_, error) in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}



extension CloudStorable {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: String(describing: Self.self))
        let mirror = Mirror(reflecting: self)
        
        for child in mirror.children {
            if let key = child.label {
                record.setValue(child.value, forKey: key)
            }
        }
        
        return record
    }
    
    static public func fromCKRecord(_ record: CKRecord) -> Self? {
        var initializers: [String: Any] = [:]
        
        let mirror = Mirror(reflecting: Self.self)
        for child in mirror.children {
            if let key = child.label, let value = record[key] {
                initializers[key] = value
            }
        }
        
        return Self.init(from: record)
    }
}

