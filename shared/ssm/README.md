# System Manager / Parameter Store

파라미터 스토어는 람다, EC2, ECS 등 AWS 리소스에서 사용가능한 key: value 저장소입니다. 외부에 노출되면 곤란한 환경변수들을 보관하고, 애플리케이션 배포 시 환경변수로 쓸때 이용하면 좋습니다. 각 애플리케이션에서 ECS에 배포하기 위해 정의하는 `task-definition.json` 파일을 확인해보세요. 

**주의사항**

환경변수의 값은 Git 저장소에도 올라가지 않도록 신경써야 합니다. 본 모듈 이용시 로컬에 `terraform.tfvars` 파일을 만들어서 배포할 수 있습니다.
