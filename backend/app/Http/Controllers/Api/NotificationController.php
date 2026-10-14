<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use App\Services\Notification\NotificationService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;

class NotificationController extends Controller
{
    public function __construct(
        protected NotificationService $notificationService
    ) {}

    /**
     * Tampilkan daftar notifikasi milik pengguna yang sedang login.
     */
    public function index(Request $request): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! $currentUser) {
            return $this->errorResponse('Akses tidak diizinkan. Silakan login kembali.', null, 401);
        }

        $unreadOnly = $request->boolean('unread_only', false);
        $perPage = min(max((int) $request->input('per_page', 20), 1), 100);

        $paginator = $this->notificationService->getUserNotifications($currentUser, $unreadOnly, $perPage);
        $unreadCount = $this->notificationService->getUnreadCount($currentUser);

        $notifications = collect($paginator->items())->map(function ($item) {
            return [
                'id_notifications' => $item->id_notifications,
                'type' => $item->type,
                'title' => $item->title,
                'message' => $item->message,
                'data' => $item->data,
                'is_read' => (bool) $item->is_read,
                'read_at' => $item->read_at?->toIso8601String(),
                'created_at' => $item->created_at?->toIso8601String(),
                'time_ago' => $item->created_at?->locale('id')->diffForHumans(),
            ];
        });

        return $this->successResponse([
            'notifications' => $notifications,
            'unread_count' => $unreadCount,
            'pagination' => [
                'current_page' => $paginator->currentPage(),
                'per_page' => $paginator->perPage(),
                'total' => $paginator->total(),
                'last_page' => $paginator->lastPage(),
            ],
        ], 'Daftar notifikasi berhasil diambil.');
    }

    /**
     * Ambil jumlah notifikasi yang belum dibaca untuk badge navbar.
     */
    public function unreadCount(): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! $currentUser) {
            return $this->errorResponse('Akses tidak diizinkan.', null, 401);
        }

        $count = $this->notificationService->getUnreadCount($currentUser);

        return $this->successResponse([
            'unread_count' => $count,
        ], 'Jumlah notifikasi belum dibaca berhasil diambil.');
    }

    /**
     * Tandai satu notifikasi sebagai telah dibaca.
     */
    public function markAsRead(string|int $id): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! $currentUser) {
            return $this->errorResponse('Akses tidak diizinkan.', null, 401);
        }

        $notification = $this->notificationService->markAsRead((int) $id, $currentUser);

        if (! $notification) {
            return $this->errorResponse('Notifikasi tidak ditemukan.', null, 404);
        }

        $unreadCount = $this->notificationService->getUnreadCount($currentUser);

        return $this->successResponse([
            'id_notifications' => $notification->id_notifications,
            'is_read' => true,
            'read_at' => $notification->read_at?->toIso8601String(),
            'unread_count' => $unreadCount,
        ], 'Notifikasi telah ditandai sebagai dibaca.');
    }

    /**
     * Tandai seluruh notifikasi milik pengguna sebagai telah dibaca.
     */
    public function markAllAsRead(): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! $currentUser) {
            return $this->errorResponse('Akses tidak diizinkan.', null, 401);
        }

        $updatedCount = $this->notificationService->markAllAsRead($currentUser);

        return $this->successResponse([
            'marked_count' => $updatedCount,
            'unread_count' => 0,
        ], 'Seluruh notifikasi telah berhasil ditandai sebagai dibaca.');
    }

    /**
     * Hapus satu notifikasi.
     */
    public function destroy(string|int $id): JsonResponse
    {
        /** @var User|null $currentUser */
        $currentUser = Auth::user();

        if (! $currentUser) {
            return $this->errorResponse('Akses tidak diizinkan.', null, 401);
        }

        $deleted = $this->notificationService->deleteNotification((int) $id, $currentUser);

        if (! $deleted) {
            return $this->errorResponse('Notifikasi tidak ditemukan.', null, 404);
        }

        $unreadCount = $this->notificationService->getUnreadCount($currentUser);

        return $this->successResponse([
            'deleted_id' => (int) $id,
            'unread_count' => $unreadCount,
        ], 'Notifikasi berhasil dihapus.');
    }
}
