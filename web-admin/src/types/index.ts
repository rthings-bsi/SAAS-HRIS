/**
 * TypeScript Interfaces & Models for Standalone HRIS & SPK SMART
 * Based on API_SPEC.md & ERD.md
 */

// ==========================================
// 1. Common API Response Types
// ==========================================

export interface ApiResponse<T = unknown> {
  success: boolean;
  message: string;
  data: T;
  errors: Record<string, string[]> | null;
}

export interface ApiPaginationMeta {
  current_page: number;
  per_page: number;
  total: number;
  last_page: number;
}

export interface PaginatedResponse<T> {
  success: boolean;
  message: string;
  data: T[];
  meta: ApiPaginationMeta;
  errors: null;
}

// ==========================================
// 2. Auth & User Entities
// ==========================================

export type UserRole = "superadmin" | "super_admin" | "owner" | "hr" | "manager" | "employee";

export interface User {
  id_users: number;
  id_companies: number | null;
  name: string;
  email: string;
  role: UserRole;
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
  employee?: Employee;
  company?: Company;
}

export interface AuthSession {
  token?: string;
  access_token?: string;
  token_type?: string;
  user: User;
  company?: Company;
  employee?: Employee;
}

// ==========================================
// 3. Organization & Branch Entities
// ==========================================

export type SubscriptionStatus = "trial" | "active" | "expired" | "canceled" | "suspended";

export interface PlatformStats {
  total_companies: number;
  active_companies: number;
  trial_companies: number;
  suspended_companies: number;
  total_employees: number;
}

export interface CompanyWithCounts extends Company {
  users_count?: number;
  employees_count?: number;
  branches_count?: number;
  departments_count?: number;
  job_positions_count?: number;
  users?: User[];
}

export interface Company {
  id_companies: number;
  name: string;
  slug: string;
  email: string;
  phone: string;
  address?: string;
  logo_url?: string;
  subscription_status: SubscriptionStatus;
  trial_ends_at?: string;
  created_at?: string;
  updated_at?: string;
}

export interface Branch {
  id_branches: number;
  id_companies: number;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  radius_meters: number;
  created_at?: string;
  updated_at?: string;
}

export interface Department {
  id_departments: number;
  id_companies: number;
  name: string;
  created_at?: string;
  updated_at?: string;
}

export interface JobPosition {
  id_job_positions: number;
  id_companies: number;
  name: string;
  created_at?: string;
  updated_at?: string;
}

// ==========================================
// 4. Employee & Shift Entities
// ==========================================

export type Gender = "male" | "female";
export type EmploymentStatus = "permanent" | "contract" | "probation";

export interface Employee {
  id_employees: number;
  id_companies: number;
  id_users: number;
  id_branches: number;
  id_departments?: number;
  id_job_positions?: number;
  nik: string;
  name?: string;
  phone: string;
  gender: Gender;
  birth_date: string;
  hire_date: string;
  employment_status: EmploymentStatus;
  basic_salary: number;
  allowance_fixed: number;
  bank_name?: string;
  bank_account_number?: string;
  bank_account_holder?: string;
  user?: User;
  branch?: Branch;
  department?: Department;
  job_position?: JobPosition;
  created_at?: string;
  updated_at?: string;
}

export interface Shift {
  id_shifts: number;
  id_companies: number;
  name: string;
  start_time: string; // HH:mm:ss
  end_time: string;   // HH:mm:ss
  late_tolerance_minutes: number;
  created_at?: string;
  updated_at?: string;
}

export interface EmployeeShift {
  id_employee_shifts: number;
  id_companies: number;
  id_employees: number;
  id_shifts: number;
  date: string; // YYYY-MM-DD
  employee?: Employee;
  shift?: Shift;
}

// ==========================================
// 5. Attendance Entities
// ==========================================

export type AttendanceStatus =
  | "present"     // Hadir tepat waktu
  | "on_time"     // Tepat waktu (rekap)
  | "late"        // Terlambat
  | "absent"      // Alpha
  | "leave"       // Cuti / Izin
  | "early_leave"; // Pulang cepat

export interface Attendance {
  id_attendances: number;
  id_companies: number;
  id_employees: number;
  date: string; // YYYY-MM-DD
  clock_in_time?: string;
  clock_in_latitude?: number;
  clock_in_longitude?: number;
  clock_in_photo_path?: string;
  clock_in_distance_meters?: number;
  clock_out_time?: string;
  clock_out_latitude?: number;
  clock_out_longitude?: number;
  clock_out_photo_path?: string;
  clock_out_distance_meters?: number;
  status: AttendanceStatus;
  late_duration_minutes: number;
  early_leave_minutes: number;
  notes?: string;
  employee?: Employee;
  created_at?: string;
  updated_at?: string;
}

export interface TodayAttendance {
  employee?: Employee;
  branch?: Branch;
  shift?: Shift;
  attendance?: Attendance | null;
}

// ==========================================
// 6. Leave & Permission Entities
// ==========================================

export type LeaveRequestStatus = "pending" | "approved" | "rejected";

export interface LeaveType {
  id_leave_types: number;
  id_companies: number;
  name: string;
  quota_days: number;
  is_paid: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface LeaveRequest {
  id_leave_requests: number;
  id_companies: number;
  id_employees: number;
  id_leave_types: number;
  start_date: string;
  end_date: string;
  total_days: number;
  reason: string;
  attachment_url?: string;
  status: LeaveRequestStatus;
  approved_by?: number;
  rejected_reason?: string;
  employee?: Employee;
  leave_type?: LeaveType;
  created_at?: string;
  updated_at?: string;
}

export interface LeaveBalance {
  id_leave_types: number;
  name: string;
  quota_days: number;
  used_days: number;
  pending_days: number;
  remaining_days: number;
  available_days: number;
  is_paid: boolean;
  year: number;
}

// ==========================================
// 6b. Overtime Entities
// ==========================================

export type OvertimeRequestStatus = "pending" | "approved" | "rejected";

export interface OvertimeRequest {
  id_overtime_requests: number;
  id_companies: number;
  id_employees: number;
  date: string;
  start_time: string;
  end_time: string;
  duration_hours: number;
  reason: string;
  status: OvertimeRequestStatus;
  approved_by?: number | null;
  rejected_reason?: string | null;
  employee?: Employee;
  approver?: User;
  created_at?: string;
  updated_at?: string;
}

// ==========================================
// 7. Payroll Entities
// ==========================================

export type PayrollPeriodStatus = "draft" | "calculated" | "finalized";

export interface PayrollPeriod {
  id_payroll_periods: number;
  id_companies: number;
  name: string;
  start_date: string;
  end_date: string;
  payment_date: string;
  status: PayrollPeriodStatus;
  created_at?: string;
  updated_at?: string;
}

export interface PayrollSlip {
  id_payroll_slips: number;
  id_companies?: number;
  id_payroll_periods: number;
  id_employees: number;
  basic_salary: number;
  allowance_fixed: number;
  overtime_pay?: number;
  deduction_late?: number;
  deduction_absence?: number;
  deductions_late?: number;
  deductions_absence?: number;
  deduction_other?: number;
  net_salary: number;
  pdf_path?: string;
  pdf_url?: string;
  has_pdf?: boolean;
  period_name?: string;
  payment_date?: string;
  status?: string;
  employee?: {
    id_employees?: number;
    name?: string;
    nik?: string;
    department?: string;
    job_position?: string;
    user?: User;
  } | Employee;
  created_at?: string;
  updated_at?: string;
}

// ==========================================
// 8. Performance Evaluation (SPK SMART)
// ==========================================

export type CriterionType = "benefit" | "cost";
export type PerformancePeriodStatus = "draft" | "active" | "calculated" | "finalized";

export interface PerformanceCriterion {
  id_performance_criteria: number;
  code: string;
  name: string;
  type: CriterionType;
  weight: number;
  c_min: number;
  c_max: number;
  source_type: "manual" | "attendance";
  is_active: boolean;
  created_at?: string;
  updated_at?: string;
}

export interface PerformancePeriod {
  id_performance_periods: number;
  name: string;
  start_date: string;
  end_date: string;
  status: PerformancePeriodStatus;
  evaluations_count?: number;
  created_at?: string;
  updated_at?: string;
}

export interface PerformanceEvaluationDetail {
  id_performance_evaluation_details: number;
  id_performance_evaluations: number;
  id_performance_criteria: number;
  raw_score: number;
  normalized_weight: number;
  utility_score: number;
  weighted_score: number;
  criterion?: PerformanceCriterion;
}

export interface PerformanceEvaluation {
  id_performance_evaluations: number;
  id_performance_periods: number;
  id_employees: number;
  final_score: number | null;
  rank: number | null;
  grade: string | null;
  recommendation: string | null;
  notes?: string | null;
  evaluated_by?: number | null;
  employee?: Employee;
  details?: PerformanceEvaluationDetail[];
  created_at?: string;
  updated_at?: string;
}

