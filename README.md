# CI / CD
Esta aplicação usa GitHub como repositório base. Toda vez que um merge na master é executado, a aplicação AWS no GitHub executa uma chamada para o AWS CodeBuild. O CodeBuild, por sua vez, compila, e salva o container no ECR. Se obtiver sucesso, o CodeBuild inicializa o Terraform para aplicar a atualização na infra.
## Design Atual
<img src="/src/Content/Images/CurrentDesign.svg" width="200" alt="Design Atual" />

## Processo de Deploy
<img src="/src/Content/Images/DeploymentProccess.svg" width="550" alt="Processo de Deploy" />

## Tecnologias

.NET C# | AWS | Terraform | AWS | GITHUB | GIT | CSS | JS
