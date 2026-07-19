# Helm Best Practices - Hướng dẫn thực thi chuẩn hóa trong Kubernetes

Tài liệu này tổng hợp các Best Practices (thực hành tốt nhất) khi làm việc với Helm, giúp bạn xây dựng, quản lý và triển khai các ứng dụng lên Kubernetes một cách an toàn, dễ mở rộng và bảo trì.

---

## 1. Tổ chức cấu trúc thư mục (Project Directory Layout)
Khi dự án lớn lên, việc gộp chung tất cả cấu hình và chart vào một nơi sẽ gây ra sự hỗn loạn. Hãy áp dụng mô hình **Phân tách rạch ròi giữa Khuôn mẫu (Charts) và Cấu hình theo môi trường (Environments)**.

### Mô hình GitOps đề xuất:
```text
k8s-deployments/
├── charts/                     # Chứa mã nguồn các Chart tự viết (Khuôn mẫu)
│   └── mynginx/
│       ├── Chart.yaml
│       ├── templates/          # Chứa manifests (Deployment, Service, Ingress...)
│       └── values.yaml         # Cấu hình MẶC ĐỊNH (tối thiểu để chạy được ở local)
│
├── environments/               # Chứa giá trị cấu hình thực tế cho từng môi trường
│   ├── dev/
│   │   ├── values-nginx.yaml   # Ghi đè cấu hình Nginx cho môi trường DEV
│   │   └── values-mariadb.yaml # Cấu hình Database cho môi trường DEV
│   └── prod/
│       ├── values-nginx.yaml   # Ghi đè cấu hình Nginx cho môi trường PROD (RAM/CPU cao hơn)
│       └── values-mariadb.yaml # Cấu hình Database cho môi trường PROD (Replicas/Cluster)
```

> **Nguyên tắc vàng:** File `values.yaml` nằm bên trong thư mục Chart chỉ nên chứa cấu hình mặc định ở mức cơ bản nhất để chạy dev/local. Cấu hình thực tế cho các môi trường (Dev, Staging, Prod) phải được lưu ở ngoài Chart và nạp vào thông qua tùy chọn `-f` khi cài đặt.

---

## 2. Quản lý Dependencies (Sub-charts) đúng cách
Sử dụng dependency trong file `Chart.yaml` giúp bạn gộp các chart lại với nhau. Tuy nhiên, cần tránh lạm dụng:

* **KHÔNG dùng sub-charts cho các thành phần lớn, có vòng đời độc lập:**
  * Ví dụ: Không nên khai báo Database (PostgreSQL, MariaDB), Redis, Kafka hay API Gateway làm dependency của ứng dụng web.
  * *Lý do:* Mỗi lần cập nhật ứng dụng web, Helm sẽ quét lại toàn bộ database. Nếu xảy ra lỗi hoặc rolling update ngoài ý muốn, database có thể bị downtime, ảnh hưởng nghiêm trọng đến dữ liệu hệ thống.
* **NÊN dùng sub-charts cho các thành phần phụ thuộc cứng (Tightly Coupled):**
  * Ví dụ: Một ứng dụng Helper chạy ngầm (Cronjob dọn dẹp log, Sidecar proxy) đi kèm với ứng dụng chính và không phục vụ cho ứng dụng nào khác.
* **Tận dụng Helm Charts chuẩn hóa:**
  * Thay vì tự viết chart cho Database, hãy sử dụng các chart uy tín từ các nhà phát triển lớn như **Bitnami** và chỉ viết file values cấu hình tùy biến lại.
* **Đối với các công cụ lớn, chuẩn thế giới (ArgoCD, Prometheus, Grafana...):**
  * Bạn **KHÔNG cần phải tạo hay copy cả một thư mục cấu trúc Helm Chart to đùng** (gồm `templates/`, `Chart.yaml`, `_helpers.tpl`...) để chứa đống code manifest của các công cụ này dưới máy của bạn.
  * Lý do là các công cụ này đã được các tổ chức lớn (như Argo Project, Prometheus-Community) viết sẵn các Helm Chart vô cùng chuẩn chỉnh và lưu trữ trên các Registry công khai trực tuyến.
  * Bạn vẫn cần một thư mục trên máy để cất các file `values.yaml` cấu hình tùy biến của mình, nhưng thư mục đó cực kỳ tối giản. Ví dụ:
    ```text
    my-k8s-config/
    ├── values-argocd.yaml     # Chỉ chứa các cấu hình bạn muốn ghi đè của ArgoCD
    ├── values-prometheus.yaml # Chỉ chứa các cấu hình bạn muốn ghi đè của Prometheus
    └── values-mariadb.yaml    # Chỉ chứa các cấu hình bạn muốn ghi đè của MariaDB
    ```
  * **Cơ chế hoạt động "Kéo code trên mạng, đập cấu hình dưới máy":**
    Khi bạn đứng tại thư mục `my-k8s-config` và chạy lệnh cài đặt:
    ```bash
    helm install argocd argo/argo-cd -f values-argocd.yaml
    ```
    * **Bước 1 (Lấy Template - Khuôn mẫu):** Helm Client nhìn vào repo `argo/argo-cd`, nó tự động lên kho lưu trữ trực tuyến để tải toàn bộ đống file template (deployment, service, ingress...) về bộ nhớ tạm. Bạn không cần tải hay quản lý đống code template phức tạp này dưới máy mình.
    * **Bước 2 (Hợp nhất cấu hình - Thông số):** Helm lấy đống template tạm thời đó, đổ file cấu hình `values-argocd.yaml` (đang nằm dưới máy của bạn) vào để sinh ra file manifest Kubernetes cuối cùng.
    * **Bước 3 (Triển khai):** Đẩy thẳng kết quả manifest đã hợp nhất lên cụm Kubernetes (ví dụ: Minikube, K3s, v.v.).

---

## 3. Quản lý cấu hình nhạy cảm (Secrets Management)
Lưu trữ plaintext mật khẩu, API token, khoá SSH trực tiếp vào Git là lỗi bảo mật cực kỳ nghiêm trọng.

* **KHÔNG commit plaintext secret lên git:** Không bao giờ viết mật khẩu vào `values.yaml` hay `values-prod.yaml` rồi đẩy lên GitHub.
* **Các giải pháp khuyên dùng:**
  1. **Sealed Secrets (Bitnami):** Mã hóa Secrets thành các SealedSecrets an toàn để commit lên Git. Chỉ có controller chạy trong cụm K8s mới giải mã được.
  2. **External Secrets Operator (ESO):** Đồng bộ secret từ các bên thứ ba (AWS Secrets Manager, HashiCorp Vault, Google Secret Manager) trực tiếp vào Kubernetes Secrets.
  3. **Helm Secrets (kết hợp với SOPS):** Mã hoá các file `secrets.yaml` bằng khoá KMS hoặc PGP trước khi push lên Git và tự động giải mã khi chạy lệnh `helm install`.

---

## 4. Viết Template sạch và an toàn (Clean Templates)
* **Sử dụng Helper Templates (`_helpers.tpl`):**
  * Gom các cụm logic lặp đi lặp lại (như định nghĩa nhãn `labels`, định nghĩa tên ứng dụng `fullname`) vào helper template bằng cú pháp `{{ define }}` để đảm bảo tính nhất quán (DRY - Don't Repeat Yourself).
* **Luôn khai báo Resource Requests & Limits:**
  * Đảm bảo mọi container đều cấu hình RAM/CPU tối thiểu và tối đa trong `values.yaml` để Kubernetes Scheduler có thể phân bổ tài nguyên hợp lý, tránh việc một Pod ngốn sạch tài nguyên của Node.
* **Luôn định nghĩa Liveness và Readiness Probes:**
  * Cấu hình các đầu kiểm tra trạng thái sức khỏe của ứng dụng nhằm giúp Kubernetes tự động khởi động lại Pod khi bị treo (Liveness) hoặc không điều hướng traffic vào Pod chưa sẵn sàng khởi chạy xong (Readiness).

---

## 5. Quản lý phiên bản (Versioning) chuyên nghiệp
Helm sử dụng 2 loại phiên bản trong `Chart.yaml`:
```yaml
version: 1.2.3     # Phiên bản của chính Helm Chart đó (Sử dụng SemVer)
appVersion: 2.1.0  # Phiên bản của ứng dụng nguồn/Docker Image bên trong
```

* **Tuân thủ Semantic Versioning (SemVer) cho `version`:**
  * **Patch (1.2.x):** Khi bạn chỉ sửa lỗi nhỏ trong template hoặc cập nhật cấu hình mặc định.
  * **Minor (1.x.0):** Khi bạn thêm tính năng mới vào template nhưng không làm gãy cấu hình cũ.
  * **Major (x.0.0):** Khi bạn thay đổi cấu trúc lớn gây lỗi không tương thích ngược (ví dụ thay đổi tên biến cấu hình quan trọng).
* **Tránh dùng tag `latest` cho Container Image:**
  * Luôn chỉ định rõ tag cụ thể của Docker Image (ví dụ: `appVersion: "v1.16.0"`). Việc dùng `latest` khiến bạn khó rollback và dễ xảy ra lỗi ngoài ý muốn khi container tự động pull bản mới nhất từ Docker Registry.

---

## 6. Kiểm thử và Xác thực (Lint & Dry-run)
Trước khi đóng gói hoặc áp dụng cấu hình lên cụm Kubernetes, hãy thực hiện kiểm tra lỗi cú pháp và logic:

* **Kiểm tra cú pháp (Linting):**
  ```bash
  helm lint ./mynginx
  ```
* **Chạy thử và sinh Manifest ảo (Dry-run & Template):**
  * Lệnh sinh ra toàn bộ code YAML thực tế để bạn kiểm tra xem các giá trị đã map đúng vị trí chưa:
    ```bash
    helm template demo-nginx ./mynginx -f environments/dev/values-nginx.yaml
    ```
  * Lệnh gửi manifest lên Kubernetes API để giả lập cài đặt xem K8s có chấp nhận hay không (không tạo tài nguyên thật):
    ```bash
    helm install demo-nginx ./mynginx --dry-run --debug
    ```
* **Viết Helm Tests:**
  * Tạo các kịch bản test tích hợp bên trong thư mục `templates/tests/` (ví dụ kiểm tra xem ứng dụng có trả về HTTP 200 hay không). Sau đó kiểm tra bằng lệnh:
    ```bash
    helm test demo-nginx
    ```
