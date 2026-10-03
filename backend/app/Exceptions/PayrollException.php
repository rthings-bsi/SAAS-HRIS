<?php

namespace App\Exceptions;

use Exception;

class PayrollException extends Exception
{
    protected int $statusCode;

    public function __construct(string $message, int $statusCode = 400)
    {
        parent::__construct($message);
        $this->statusCode = $statusCode;
    }

    public function getStatusCode(): int
    {
        return $this->statusCode;
    }

    public function render($request)
    {
        return response()->json([
            'success' => false,
            'message' => $this->getMessage(),
            'data' => null,
            'errors' => null,
        ], $this->statusCode);
    }
}
