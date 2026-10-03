import axios, { AxiosError, InternalAxiosRequestConfig } from "axios";
import type { ApiResponse } from "@/types";

export class ApiError extends Error {
  errors?: Record<string, string[]>;
  status?: number;

  constructor(message: string, errors?: Record<string, string[]>, status?: number) {
    super(message);
    this.name = "ApiError";
    this.errors = errors;
    this.status = status;
    Object.setPrototypeOf(this, ApiError.prototype);
  }
}

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_URL || "http://localhost:8000/api/v1";

export const apiClient = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    Accept: "application/json",
    "Content-Type": "application/json",
  },
  timeout: 15000,
});

// Request Interceptor: Attach Sanctum Token
apiClient.interceptors.request.use(
  (config: InternalAxiosRequestConfig) => {
    if (typeof window !== "undefined") {
      const token = localStorage.getItem("hris_token");
      if (token && config.headers) {
        config.headers.Authorization = `Bearer ${token}`;
      }
    }
    return config;
  },
  (error) => {
    return Promise.reject(error);
  }
);

// Response Interceptor: Handle Global 401 & Extract Structured Errors
apiClient.interceptors.response.use(
  (response) => {
    return response;
  },
  (error: AxiosError<ApiResponse<unknown>>) => {
    if (error.response?.status === 401) {
      if (typeof window !== "undefined") {
        localStorage.removeItem("hris_token");
        localStorage.removeItem("hris_user");
        if (
          !window.location.pathname.startsWith("/login") &&
          !window.location.pathname.startsWith("/register")
        ) {
          // eslint-disable-next-line @next/next/no-location-assign-relative-destination
          window.location.href = "/login";
        }
      }
    }

    const message =
      error.response?.data?.message ||
      error.message ||
      "Terjadi kendala pada koneksi server.";

    const errors = (error.response?.data?.errors as Record<string, string[]> | undefined) || undefined;
    const status = error.response?.status;

    return Promise.reject(new ApiError(message, errors, status));
  }
);

export default apiClient;
