# Estilo

Segue o estilo "vanilla Rails" do 37signals, como no beep.

- **Condicionais:** prefira `if/else` expandido a guard clause. Guard só no começo de um método cujo corpo não é trivial.
- **Ordem:** métodos de classe, depois públicos (`initialize` primeiro), depois privados. Métodos na ordem em que são chamados.
- **Visibilidade:** sem linha em branco depois de `private`; os métodos privados ficam indentados sob ele.
- **Bang:** `!` só quando existe a versão sem `!`.
- **Controllers:** CRUD. Ação que não é CRUD vira recurso novo (`resource :celebration`, não `post :celebrate`). Controller magro, model rico.
- **Models:** concerns do model em `app/models/<model>/` (`User::Traveler`), incluídos pelo nome curto. POROs no namespace. `app/models/concerns/` só pro que é compartilhado. Sem `app/services`.
- **Texto:** pt-BR escrito direto, tom de jogo mas claro. Nunca "falhou"/"perdeu".
