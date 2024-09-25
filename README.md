# iCloud Manager

`iCloudManager` é um pacote Swift projetado para facilitar o uso do CloudKit em seus aplicativos iOS. A classe genérica `CloudManager` simplifica o processo de interagir com o CloudKit, permitindo operações CRUD (Criar, Ler, Atualizar e Deletar) em registros do iCloud de forma mais intuitiva.

## Índice

1. [Requisitos](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
2. [Instalação](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
3. [Como Usar](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
    - [1. Conformidade com `CloudStorable`](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
    - [2. Inicialização do `CloudManager`](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
    - [3. Operações CRUD](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
        - [Criar (Create)](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
        - [Ler (Read)](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
        - [Atualizar (Update)](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
        - [Deletar (Delete)](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
    - [4. Relacionamentos entre Registros](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
4. [Exemplos](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
    - [Definindo um Modelo de Dados](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
    - [Usando o `CloudManager`](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
5. [Considerações Adicionais](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)
6. [Notas](https://www.notion.so/iCloud-Manager-10c1d68b57be80029dd4f4581c5b28a2?pvs=21)

## Requisitos

- iOS 15.0 ou superior.
- Xcode 13 ou superior.
- Seu projeto deve estar configurado para usar o CloudKit e possuir as permissões adequadas no portal do desenvolvedor da Apple.

## Instalação

Adicione o `iCloudManager` ao seu projeto usando o Swift Package Manager:

1. No Xcode, vá em **File > Add Packages...**
2. Insira o repositório do `iCloudManager`.
3. Selecione a versão desejada e adicione o pacote ao seu projeto.

## Como Usar

### 1. Conformidade com `CloudStorable`

O primeiro passo é garantir que o tipo que você deseja salvar no CloudKit conforme com o protocolo `CloudStorable`. Isso significa que você precisa implementar os métodos `fromCKRecord` e `toCKRecord` para mapear suas propriedades para um `CKRecord`.

```swift
import CloudKit

public protocol CloudStorable {
    static func fromCKRecord(_ record: CKRecord) -> Self?
    func toCKRecord() -> CKRecord
    func isSameAs(_ other: Self) -> Bool
}

```

### 2. Inicialização do `CloudManager`

Crie uma instância de `CloudManager` passando o seu tipo que conforma com `CloudStorable`:

```swift
let manager = CloudManager<MyData>()

```

### 3. Operações CRUD

### Criar (Create)

Para salvar um novo item no CloudKit:

```swift
manager.saveItem(newItem) { result in
    switch result {
    case .success(let savedItem):
        print("Item salvo com sucesso: \\(savedItem)")
    case .failure(let error):
        print("Erro ao salvar item: \\(error.localizedDescription)")
    }
}

```

### Ler (Read)

Para buscar todos os itens:

```swift
manager.fetchItems { result in
    switch result {
    case .success(let items):
        print("Itens recuperados: \\(items)")
    case .failure(let error):
        print("Erro ao buscar itens: \\(error.localizedDescription)")
    }
}

```

Você também pode utilizar um `NSPredicate` para filtrar os resultados:

```swift
let predicate = NSPredicate(format: "age > %d", 18)
manager.fetchItems(withPredicate: predicate) { result in
    // ...
}

```

### Atualizar (Update)

Para atualizar um item existente:

```swift
manager.updateItem(updatedItem) { result in
    switch result {
    case .success(let item):
        print("Item atualizado: \\(item)")
    case .failure(let error):
        print("Erro ao atualizar item: \\(error.localizedDescription)")
    }
}

```

### Deletar (Delete)

Para deletar um item:

```swift
manager.deleteItem(itemToDelete) { result in
    switch result {
    case .success():
        print("Item deletado com sucesso.")
    case .failure(let error):
        print("Erro ao deletar item: \\(error.localizedDescription)")
    }
}

```

### 4. Relacionamentos entre Registros

Se você tem relacionamentos entre registros, pode utilizar o protocolo `Relatable` e os métodos fornecidos para salvar pais com seus filhos:

```swift
manager.saveParentWithChildren(parent: parentItem, children: childItems) { result in
    // ...
}

```

E para buscar filhos de um pai:

```swift
manager.fetchChildrenForParent(parent: parentItem) { result in
    // ...
}

```

## Exemplos

### Definindo um Modelo de Dados

Aqui está um exemplo de como definir uma estrutura que conforma com `CloudStorable`:

```swift
import CloudKit

struct MyData: CloudStorable {
    var id: CKRecord.ID
    var name: String
    var age: Int

    // Conformidade com CloudStorable
    static func fromCKRecord(_ record: CKRecord) -> MyData? {
        guard let name = record["name"] as? String,
              let age = record["age"] as? Int else {
            return nil
        }
        return MyData(id: record.recordID, name: name, age: age)
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "MyData", recordID: id)
        record["name"] = name as CKRecordValue
        record["age"] = age as CKRecordValue
        return record
    }

    func isSameAs(_ other: MyData) -> Bool {
        return self.id == other.id
    }
}

```

Se você tem relacionamentos, como um pai com filhos:

```swift
struct ChildData: Relatable {
    var id: CKRecord.ID
    var name: String
    var parentRef: CKRecord.Reference?

    // Conformidade com CloudStorable
    static func fromCKRecord(_ record: CKRecord) -> ChildData? {
        guard let name = record["name"] as? String else {
            return nil
        }
        let parentRef = record["parentRef"] as? CKRecord.Reference
        return ChildData(id: record.recordID, name: name, parentRef: parentRef)
    }

    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "ChildData", recordID: id)
        record["name"] = name as CKRecordValue
        if let parentRef = parentRef {
            record["parentRef"] = parentRef
        }
        return record
    }

    func isSameAs(_ other: ChildData) -> Bool {
        return self.id == other.id
    }
}

```

### Usando o `CloudManager`

### Inicialização

```swift
let manager = CloudManager<MyData>()

```

### Criar um Novo Item

```swift
let newItem = MyData(
    id: CKRecord.ID(recordName: UUID().uuidString),
    name: "John Doe",
    age: 30
)

manager.saveItem(newItem) { result in
    switch result {
    case .success(let savedItem):
        print("Item salvo com sucesso: \\(savedItem)")
    case .failure(let error):
        print("Erro ao salvar item: \\(error.localizedDescription)")
    }
}

```

### Buscar Itens

```swift
manager.fetchItems { result in
    switch result {
    case .success(let items):
        print("Itens recuperados: \\(items)")
    case .failure(let error):
        print("Erro ao buscar itens: \\(error.localizedDescription)")
    }
}

```

### Atualizar um Item

```swift
var itemToUpdate = existingItem
itemToUpdate.name = "Jane Doe"

manager.updateItem(itemToUpdate) { result in
    switch result {
    case .success(let updatedItem):
        print("Item atualizado: \\(updatedItem)")
    case .failure(let error):
        print("Erro ao atualizar item: \\(error.localizedDescription)")
    }
}

```

### Deletar um Item

```swift
manager.deleteItem(itemToDelete) { result in
    switch result {
    case .success():
        print("Item deletado com sucesso.")
    case .failure(let error):
        print("Erro ao deletar item: \\(error.localizedDescription)")
    }
}

```

### Trabalhando com Relacionamentos

Salvar um pai com seus filhos:

```swift
let parentItem = MyData(
    id: CKRecord.ID(recordName: UUID().uuidString),
    name: "Parent Item",
    age: 50
)

let childItem1 = ChildData(
    id: CKRecord.ID(recordName: UUID().uuidString),
    name: "Child 1",
    parentRef: nil
)

let childItem2 = ChildData(
    id: CKRecord.ID(recordName: UUID().uuidString),
    name: "Child 2",
    parentRef: nil
)

manager.saveParentWithChildren(parent: parentItem, children: [childItem1, childItem2]) { result in
    switch result {
    case .success():
        print("Pai e filhos salvos com sucesso.")
    case .failure(let error):
        print("Erro ao salvar pai e filhos: \\(error.localizedDescription)")
    }
}

```

Buscar os filhos de um pai:

```swift
manager.fetchChildrenForParent(parent: parentItem) { (result: Result<[ChildData], Error>) in
    switch result {
    case .success(let children):
        print("Filhos recuperados: \\(children)")
    case .failure(let error):
        print("Erro ao buscar filhos: \\(error.localizedDescription)")
    }
}

```

## Considerações Adicionais

- **Extensibilidade:** A classe `CloudManager` é projetada para ser extensível. Você pode personalizá-la conforme necessário para atender às necessidades específicas do seu aplicativo.
- **Tratamento de Erros:** Todos os métodos fornecem feedback através de closures de conclusão com um `Result`, permitindo que você trate erros de maneira robusta.
- **Assincronicidade:** As operações com o CloudKit são assíncronas. Certifique-se de lidar adequadamente com essa característica em sua interface de usuário.

## Notas

- **Verificação do iCloud:** A classe verifica automaticamente o status da conta iCloud do usuário. Se o iCloud não estiver disponível ou configurado, a propriedade `iCloudOk` será `false`.
- **Permissões:** Certifique-se de ter as permissões adequadas e de configurar o CloudKit corretamente no portal do desenvolvedor da Apple e no seu projeto.
- **Teste:** Lembre-se de testar todas as operações em diferentes cenários para garantir a robustez e a confiabilidade da sua implementação.

