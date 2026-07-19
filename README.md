# Helm Chart Repository - Nginx Demo

Dự án này chứa các Helm Chart dùng để triển khai ứng dụng Nginx demo trên Kubernetes, được cấu trúc dưới dạng một Helm Repository giúp người dùng khác có thể cài đặt trực tiếp từ xa qua GitHub.

---

## 🚀 Hướng dẫn cài đặt (Installation)

Người khác có thể cài đặt các chart trong dự án này vào cụm Kubernetes của họ thông qua các cách dưới đây:

### Cách 1: Cài đặt thông qua GitHub Pages (Khuyên dùng)
Bạn có thể biến repository GitHub này thành một Helm Repository công khai để người khác dễ dàng đăng ký và cài đặt.

#### Bước 1: Kích hoạt GitHub Pages trên repository của bạn
1. Đi tới repository trên GitHub của bạn: [https://github.com/CTranLam/Helm](https://github.com/CTranLam/Helm).
2. Chọn **Settings** (Cài đặt) > **Pages** ở thanh menu bên trái.
3. Tại phần **Build and deployment** > **Source**, chọn **Deploy from a branch**.
4. Chọn nhánh chứa source (thường là `main` hoặc `master`) và thư mục gốc `/ (root)`, sau đó nhấn **Save**.
5. Đợi vài phút, GitHub sẽ cung cấp cho bạn một đường dẫn URL dạng: `https://ctranlam.github.io/Helm/`.

#### Bước 2: Người dùng khác thêm Repository và cài đặt
Người khác chỉ cần chạy các lệnh sau trên terminal của họ:

```bash
# 1. Thêm repository của bạn vào Helm client
helm repo add my-nginx-repo https://ctranlam.github.io/Helm/

# 2. Cập nhật danh sách chart mới nhất
helm repo update

# 3. Cài đặt chart mynginx
helm install demo-nginx my-nginx-repo/mynginx --version 0.1.0
```

---

### Cách 2: Cài đặt trực tiếp từ đường dẫn file trên GitHub (Quick Install)
Người dùng không cần thêm repository vào Helm client mà có thể chạy cài đặt trực tiếp bằng liên kết tải file `.tgz` trên GitHub:

```bash
helm install demo-nginx https://raw.githubusercontent.com/CTranLam/Helm/main/publish/mynginx-0.1.0.tgz
```

---

### Cách 3: Clone mã nguồn từ GitHub và cài đặt cục bộ
Người dùng cũng có thể clone dự án về máy và cài đặt từ thư mục chứa mã nguồn:

```bash
# 1. Clone repository về máy
git clone https://github.com/CTranLam/Helm.git

# 2. Di chuyển vào thư mục dự án
cd Helm

# 3. Cài đặt chart từ thư mục mynginx
helm install demo-nginx ./mynginx
```

---

## 🛠️ Cấu hình và Tùy biến (Configuration)

Chart `mynginx` hỗ trợ các tham số cấu hình sau (được định nghĩa trong `mynginx/values.yaml`):

| Tham số | Mô tả | Giá trị mặc định |
| :--- | :--- | :--- |
| `image` | Docker image của ứng dụng Nginx | `nginxdemos/hello:latest` |
| `port` | Port mà container lắng nghe và Service expose | `80` |
| `identity_key` | Khóa nhận diện dùng trong labels | `mynginx-identity-key` |

### Sử dụng Custom Values khi cài đặt

Để cấu hình các tham số trên khi cài đặt:

#### 1. Sử dụng file cấu hình tùy biến
Người dùng có thể tạo một file cấu hình riêng (ví dụ: `mycustomvalues.yaml`) với nội dung cần ghi đè:
```yaml
port: 8080
identity_key: "mynginx-identity-key-002"
```

Và áp dụng file này khi chạy lệnh cài đặt:
- **Nếu cài từ repo:**
  ```bash
  helm install demo-nginx my-nginx-repo/mynginx -f mycustomvalues.yaml
  ```
- **Nếu cài từ thư mục code đã clone:**
  ```bash
  helm install demo-nginx ./mynginx -f mycustomvalues.yaml
  ```

#### 2. Cấu hình trực tiếp trên dòng lệnh bằng `--set`
```bash
helm install demo-nginx my-nginx-repo/mynginx --set port=8080 --set identity_key="mynginx-identity-key-002"
```

---

## 📦 Đóng gói và Cập nhật Repository (Dành cho Owner)

Khi bạn (chủ sở hữu repo) thay đổi cấu hình chart và muốn cập nhật bản mới lên GitHub:

1. **Đóng gói lại Chart:**
   ```bash
   helm package mynginx -d publish/
   ```

2. **Cập nhật lại file chỉ mục `index.yaml`:**
   ```bash
   helm repo index . --url https://ctranlam.github.io/Helm/
   ```

3. **Commit và Push thay đổi lên GitHub:**
   ```bash
   git add .
   git commit -m "Update chart version"
   git push origin main
   ```

---

## 🔍 Kiểm tra trạng thái ứng dụng

Sau khi cài đặt thành công, người dùng có thể kiểm tra trạng thái của các tài nguyên:

```bash
# Xem danh sách các release đã cài đặt
helm list

# Kiểm tra các Pods và Services vừa tạo
kubectl get pods,svc -l app=nginx

# Gỡ bỏ (Uninstall) release nếu không dùng nữa
helm uninstall demo-nginx
```
