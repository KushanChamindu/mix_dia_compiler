# mix_dia_compiler
This is project developed my Xerion(https://github.com/xerions) and I solved first problem of this module
## This is the project URL (https://github.com/xerions/mix_dia_compiler)
As below we can specify the order of the dia file and then we can compile accordingly. 
```bash
[ %{compile_order: 1, file_name: "b.dia"}, %{compile_order: 2, file_name: "a.dia"}] 
```
This is the ordering technique we use.
```bash
Mix.Tasks.Compile.Dia.run [ %{compile_order: 1, file_name: "b.dia"}, %{compile_order: 2, file_name: "a.dia"}] 
```
If we don't want to order explicitly we can run this task as before(which Xerion developed). This version is compatible for both versions. We can run Xerion's version usinng below command.
```bash
Mix.Tasks.Compile.Dia.run []
````

## This is Exerion's project README.md file and I solved this project first issue.
![alt text](https://github.com/KushanChamindu/mix_dia_compiler/blob/main/images/mix_dia.png)