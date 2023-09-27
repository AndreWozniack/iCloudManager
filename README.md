# iCloudManager
Package to facilitate the use of CloudKit in swift. `CloudManager` is a generic class designed to simplify the process of interacting with CloudKit, allowing CRUD (Create, Read, Update and Delete) operations on iCloud records.

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
