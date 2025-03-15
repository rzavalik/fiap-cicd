# CI / CD
Esta aplicação usa GitHub como repositório base. Toda vez que um merge na master é executado, a aplicação AWS no GitHub executa uma chamada para o AWS CodeBuild. O CodeBuild, por sua vez, compila, e salva o container no ECR. Se obtiver sucesso, o CodeBuild inicializa o Terraform para aplicar a atualização na infra.
## Design Atual
<img src="/src/Content/Images/CurrentDesign.svg" width="200" alt="Design Atual" />

## Processo de Deploy
<img src="/src/Content/Images/DeploymentProccess.svg" width="550" alt="Processo de Deploy" />

## Tecnologias

<div align="left">
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/dot-net/dot-net-plain-wordmark.svg" height="40" alt=".NET"  />
  <img width="12" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/amazonwebservices/amazonwebservices-original-wordmark.svg" height="40" alt="AWS"  />
  <img width="12" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/docker/docker-plain-wordmark.svg" height="40" alt="Docker"  />
  <img width="12" />
  <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/github/github-original.svg" height="40" alt="GitHub"  />
</div>


Veja em [http://helloworld-alb-1332269203.us-east-1.elb.amazonaws.com/]
