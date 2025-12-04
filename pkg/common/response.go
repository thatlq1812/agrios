package common

// APIResponse is a standard format for all APIs
type APIResponse struct {
	Code    string      `json:"code"`
	Message string      `json:"message"`
	Data    interface{} `json:"data,omitempty"`
}

// ListData for list response
type ListData struct {
	Total   int64 `json:"total"`
	Page    int32 `json:"page"`
	Size    int32 `json:"size"`
	HasMore bool  `json:"has_more"`
}

// Response codes
const (
	CodeSuccess         = "000"
	CodeInvalidArgument = "400"
	CodeUnauthorized    = "401"
	CodeNotFound        = "404"
	CodeAlreadyExists   = "409"
	CodeInternal        = "500"
)

// NewSuccessresponse
func NewSuccessResponse(data interface{}) *APIResponse {
	return &APIResponse{
		Code:    CodeSuccess,
		Message: "success",
		Data:    data,
	}
}

// NewErrorResponse create error response
func NewErrorResponse(code, message string) *APIResponse {
	return &APIResponse{
		Code:    code,
		Message: message,
	}
}

// NewListResponse
func NewListResponse(items interface{}, total int64, page, size int32) *APIResponse {
	hasMore := int64(page*size) < total
	return &APIResponse{
		Code:    CodeSuccess,
		Message: "success",
		Data: ListData{
			Total:   total,
			Page:    page,
			Size:    size,
			HasMore: hasMore,
		},
	}
}
