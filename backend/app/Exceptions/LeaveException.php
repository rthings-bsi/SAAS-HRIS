<?php

namespace App\Exceptions;

use Exception;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class LeaveException extends Exception
{
    protected int $status;
    protected mixed $errors;

    public function __construct(string $message = 'Terjadi kesalahan pengajuan cuti.', int $status = 422, mixed $errors = null)
    {
        parent::__construct($message, $status);
        $this->status = $status;
        $this->errors = $errors;
    }

    public function getErrors(): mixed
    {
        return $this->errors;
    }

    public function render(Request $request): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
            'data' => null,
            'errors' => $this->errors,
        ], $this->status);
    }
}
