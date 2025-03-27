# EC2 

AWS EC2 관련 리소스 모음으로 Security Group과 ALB가 정의되어 있습니다. ALB의 listener 관리는 애플리케이션 인프라 레벨에서 관리합니다.

## Resources

* Security Groups
  * local-sg: 일부 IP의 80, 443 접근만 허용, 내부 접속에 사용
  * public-sg: 모든 IP의 80,443 접근을 허용, 퍼블릭 접속에 사용
  * private-sg: 프라이빗 서브넷의 Inbound & Outbound 연결을 관리
* Application Load Balancers
  * Stage Internet Facing ALB: local-sg를 붙여 allowlist ips 관리
  * Public Internet Facing ALB: public-sg를 붙여 모든 접근 허용
