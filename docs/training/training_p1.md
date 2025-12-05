Chào bạn\! Đây là những kiến thức cực kỳ **cốt lõi** và **bắt buộc** phải nắm vững khi làm **backend developer**. Yêu cầu của mentor là hoàn toàn hợp lý, bạn cần phải học và áp dụng chúng vào dự án training thực tế của mình để hiểu rõ cơ chế hoạt động.

Dưới đây là phần giải thích chi tiết về từng mục, kèm theo định nghĩa, mục đích sử dụng và ví dụ thực tế trong ngữ cảnh của một **Web API** (cụ thể là **RESTful API**).

-----

## 🌐 HTTP (Hypertext Transfer Protocol)

**HTTP** là **giao thức** nền tảng được sử dụng để truyền tải dữ liệu giữa **client** (như trình duyệt web, ứng dụng di động) và **server** (nơi lưu trữ và xử lý dữ liệu) trên World Wide Web.

  * **Định nghĩa:** Nó định nghĩa cách các thông điệp được định dạng và truyền tải, cũng như hành động nào mà server và client nên thực hiện khi nhận được các thông điệp đó.
  * **Dùng để làm gì?** Để cho phép client yêu cầu tài nguyên (như trang HTML, ảnh, dữ liệu JSON,...) từ server, và server trả về phản hồi tương ứng.
      * **Ví dụ thực tế:** Khi bạn mở một trang web, trình duyệt (client) gửi một **yêu cầu HTTP (HTTP Request)** đến server, và server trả về **phản hồi HTTP (HTTP Response)** chứa nội dung trang web đó.

[Image of HTTP request and response cycle]

-----

## 🛠️ HTTP Methods (Các Phương Thức)

Các **HTTP Method** (còn gọi là **Verb**) chỉ định **hành động** mà client muốn thực hiện trên tài nguyên được xác định bởi URL.

| Method | Mục đích | Dùng để làm gì? (Tác động lên dữ liệu) | Ví dụ thực tế trong API |
| :--- | :--- | :--- | :--- |
| **`GET`** | **Đọc** (Retrieve) | Yêu cầu server trả về một hoặc nhiều tài nguyên. **Không làm thay đổi dữ liệu** trên server (Idempotent). | Lấy danh sách sản phẩm: `GET /api/products` |
| **`POST`** | **Tạo mới** (Create) | Gửi dữ liệu để server **tạo một tài nguyên mới**. | Tạo một người dùng mới: `POST /api/users` |
| **`PUT`** | **Thay thế hoàn toàn** (Replace/Update) | Thay thế **toàn bộ** tài nguyên hiện có bằng dữ liệu mới được gửi. | Cập nhật toàn bộ thông tin sản phẩm có ID 123: `PUT /api/products/123` |
| **`DELETE`** | **Xóa** (Delete) | Xóa tài nguyên được chỉ định. (Idempotent). | Xóa người dùng có ID 456: `DELETE /api/users/456` |
| **`PATCH`** | **Cập nhật một phần** (Partial Update) | Áp dụng các chỉnh sửa **một phần** cho tài nguyên. Chỉ gửi dữ liệu cần thay đổi. | Chỉ cập nhật tên của sản phẩm có ID 123: `PATCH /api/products/123` |

> *Note:* **Idempotent** nghĩa là nếu bạn thực hiện cùng một yêu cầu nhiều lần, kết quả trên server vẫn sẽ giống nhau (không tạo thêm dữ liệu, không xóa thêm). `GET`, `PUT`, `DELETE` là Idempotent; `POST` thì không.

-----

## 🚦 HTTP Status Codes (Mã Trạng Thái)

**Status Code** là mã số 3 chữ số được server gửi lại trong **HTTP Response** để cho client biết **kết quả** của yêu cầu đã được xử lý như thế nào.

| Mã (Code) | Phân loại | Ý nghĩa | Dùng để làm gì? |
| :--- | :--- | :--- | :--- |
| **`200`** | 2xx Success | **OK** | Yêu cầu đã thành công. (Thường dùng cho `GET`, `PUT`, `PATCH`, `DELETE`). |
| **`201`** | 2xx Success | **Created** | Yêu cầu đã thành công và một tài nguyên mới đã được **tạo**. (Thường dùng cho `POST`). |
| **`400`** | 4xx Client Error | **Bad Request** | Yêu cầu không hợp lệ (ví dụ: thiếu trường dữ liệu, định dạng JSON sai, tham số không đúng). |
| **`401`** | 4xx Client Error | **Unauthorized** | Client chưa được **xác thực** (Authentication) - chưa đăng nhập, hoặc token bị thiếu/sai. |
| **`403`** | 4xx Client Error | **Forbidden** | Client đã được xác thực, nhưng **không có quyền** (Authorization) để truy cập tài nguyên đó. |
| **`404`** | 4xx Client Error | **Not Found** | Tài nguyên mà client yêu cầu **không tồn tại** trên server. |
| **`500`** | 5xx Server Error | **Internal Server Error** | Lỗi không mong muốn xảy ra bên trong server khi xử lý yêu cầu. (Lỗi code, kết nối DB,...). |

-----

## 🧩 Các Thành Phần Của HTTP Request/Response

Một thông điệp HTTP (Request hoặc Response) bao gồm các thành phần chính: **Header**, **Body**, và trong Request còn có **Query Parameter** và **Path Parameter**.

### 1\. Header

  * **Định nghĩa:** Là các cặp key-value chứa **siêu dữ liệu** (metadata) về thông điệp HTTP.
  * **Dùng để làm gì?** Cung cấp thông tin cần thiết cho việc xử lý request hoặc response.
      * **Ví dụ thực tế:**
          * **Request Header:** `Authorization: Bearer <token>` (để xác thực), `Content-Type: application/json` (cho server biết định dạng dữ liệu trong body).
          * **Response Header:** `Content-Type: application/json` (cho client biết định dạng dữ liệu trả về), `Set-Cookie` (để gửi cookie về client).

### 2\. Body

  * **Định nghĩa:** Phần chính của thông điệp, chứa **dữ liệu thực tế** được gửi đi hoặc nhận về.
  * **Dùng để làm gì?**
      * **Request Body:** Mang dữ liệu từ client lên server (ví dụ: thông tin người dùng khi đăng ký `POST /api/users`).
      * **Response Body:** Mang dữ liệu từ server về client (ví dụ: danh sách sản phẩm `GET /api/products`).

### 3\. Query Parameter (Tham số truy vấn)

  * **Định nghĩa:** Các cặp key-value được thêm vào cuối URL sau dấu `?` và phân cách nhau bằng dấu `&`.
  * **Dùng để làm gì?** Thường dùng để **lọc, sắp xếp, hoặc phân trang** dữ liệu khi dùng `GET` request.
      * **Ví dụ thực tế:** `GET /api/products?**category=electronics&sort=price_desc**`

### 4\. Path Parameter (Tham số đường dẫn)

  * **Định nghĩa:** Một phần của đường dẫn URL, dùng để **xác định duy nhất** một tài nguyên cụ thể.
  * **Dùng để làm gì?** Truy cập hoặc thao tác với một tài nguyên cụ thể.
      * **Ví dụ thực tế:** `GET /api/products/**123**` (ở đây, `123` là Path Parameter chỉ ID của sản phẩm).

-----

## 🏛️ RESTful API (Representational State Transfer)

**REST** là một **phong cách kiến trúc** (architectural style) để xây dựng các dịch vụ web. **RESTful API** là API tuân theo các nguyên tắc của kiến trúc REST.

  * **Định nghĩa:** RESTful API là một tập hợp các quy tắc cho phép các hệ thống giao tiếp với nhau qua HTTP, xem **mọi thứ là tài nguyên** (Resource).
  * **Dùng để làm gì?**
      * Cung cấp một cách thức chuẩn hóa, dễ hiểu, và có thể mở rộng để client truy cập và thao tác với dữ liệu trên server.
      * Nó thường sử dụng các HTTP Method (`GET`, `POST`, `PUT`, `DELETE`,...) và URL có cấu trúc để thực hiện các thao tác **CRUD** (Create, Read, Update, Delete) trên tài nguyên.
  * **Ví dụ thực tế:**
      * URL đại diện cho tài nguyên: `/api/users`, `/api/products/{id}`.
      * Thao tác trên tài nguyên:
          * Tạo người dùng: `POST /api/users`
          * Xem chi tiết người dùng: `GET /api/users/456`

-----

## 📦 Định Dạng Dữ Liệu

Đây là các định dạng phổ biến được sử dụng để truyền tải dữ liệu trong **Request Body** và **Response Body**.

### 1\. JSON (JavaScript Object Notation)

  * **Định nghĩa:** Là định dạng trao đổi dữ liệu **phổ biến nhất** trong các Web API hiện đại, rất dễ đọc và viết cho con người, dễ dàng phân tích và tạo ra cho máy tính.
  * **Dùng để làm gì?** Truyền tải dữ liệu có cấu trúc.
      * **Ví dụ thực tế (Request Body):**
        ```json
        {
          "name": "Nguyen Van A",
          "email": "a@example.com",
          "password": "hashed_password"
        }
        ```

### 2\. form-data (application/x-www-form-urlencoded)

  * **Định nghĩa:** Định dạng dữ liệu truyền thống được sử dụng khi gửi dữ liệu từ một form HTML. Dữ liệu được mã hóa thành các cặp key-value và nối bằng dấu `&`.
  * **Dùng để làm gì?** Thường dùng cho các form submission đơn giản.
      * **Ví dụ thực tế (Request Body):** `name=Nguyen+Van+A&email=a%40example.com`

### 3\. multipart/form-data

  * **Định nghĩa:** Một định dạng đặc biệt, được dùng khi cần gửi dữ liệu có chứa **file** (ví dụ: ảnh, video) cùng với các trường dữ liệu văn bản khác. Mỗi phần tử (trường text hoặc file) được phân cách bằng một ranh giới (boundary).
  * **Dùng để làm gì?** Upload file lên server.
      * **Ví dụ thực tế:** Gửi ảnh đại diện (`avatar`) và tên (`name`) của người dùng cùng lúc trong một request.

-----

## 🎯 Hướng Dẫn Áp Dụng Thực Tế Trong Training

Yêu cầu của mentor có nghĩa là bạn cần phải **áp dụng** những kiến thức này vào code thực tế của mình:

1.  **Thiết kế API Endpoint:**

      * Bạn cần phải tạo các **route/endpoint** (URL) cho phép client tương tác với dữ liệu của bạn, tuân thủ nguyên tắc **RESTful**.
      * *Ví dụ:* Thiết kế API cho module **Sản phẩm**:
          * `GET /api/products` (Lấy danh sách)
          * `POST /api/products` (Tạo mới)
          * `GET /api/products/{id}` (Lấy chi tiết)
          * `PUT /api/products/{id}` (Cập nhật toàn bộ)
          * `DELETE /api/products/{id}` (Xóa)

2.  **Sử dụng HTTP Method Chính Xác:**

      * Đảm bảo khi tạo mới dữ liệu dùng `POST`, khi lấy dữ liệu dùng `GET`, và khi cập nhật dùng `PUT`/`PATCH`, khi xóa dùng `DELETE`.

3.  **Xử Lý Request Data:**

      * Trong các request `POST`, `PUT`, `PATCH`, bạn phải biết cách đọc dữ liệu từ **Request Body** (thường là **JSON**) và **Validate** (kiểm tra tính hợp lệ) của dữ liệu đó.
      * Trong `GET` request, bạn phải biết cách lấy giá trị từ **Query Parameter** để lọc (ví dụ: `?status=active`) hoặc từ **Path Parameter** để truy cập tài nguyên cụ thể (ví dụ: `/123`).

4.  **Phản Hồi Chính Xác (Status Code & Body):**

      * Sau khi xử lý xong, **bắt buộc** phải trả về **Status Code** và **Response Body** phù hợp:
          * `200 OK` cho `GET` thành công.
          * `201 Created` khi tạo mới bằng `POST` thành công.
          * `400 Bad Request` nếu dữ liệu người dùng gửi lên sai.
          * `401` nếu người dùng chưa đăng nhập.
          * `404 Not Found` nếu không tìm thấy tài nguyên.
          * `500 Internal Server Error` nếu code của bạn bị lỗi.

Bạn muốn tôi cung cấp ví dụ code về cách thiết lập một **RESTful endpoint** cơ bản bằng một ngôn ngữ backend cụ thể (ví dụ: Node.js/Express, Python/Flask, Java/Spring Boot) không?