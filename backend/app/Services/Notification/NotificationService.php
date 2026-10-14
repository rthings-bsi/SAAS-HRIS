<?php

namespace App\Services\Notification;

use App\Models\Notification;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Pagination\LengthAwarePaginator;

class NotificationService
{
    /**
     * Kirim notifikasi ke seorang pengguna tertentu.
     */
    public function send(
        int $companyId,
        int $userId,
        string $type,
        string $title,
        string $message,
        ?array $data = null
    ): Notification {
        return Notification::create([
            'id_companies' => $companyId,
            'id_users' => $userId,
            'type' => $type,
            'title' => $title,
            'message' => $message,
            'data' => $data,
            'is_read' => false,
            'read_at' => null,
        ]);
    }

    /**
     * Kirim notifikasi ke seluruh admin (Owner, Super Admin, HR, Manager) dalam perusahaan.
     */
    public function notifyAdmins(
        int $companyId,
        string $type,
        string $title,
        string $message,
        ?array $data = null,
        ?int $exceptUserId = null
    ): int {
        $adminRoles = ['owner', 'superadmin', 'hr', 'manager'];

        $adminUsers = User::where('id_companies', $companyId)
            ->whereIn('role', $adminRoles)
            ->where('is_active', true)
            ->when($exceptUserId, fn ($q) => $q->where('id_users', '!=', $exceptUserId))
            ->get();

        $count = 0;
        foreach ($adminUsers as $admin) {
            $this->send($companyId, $admin->id_users, $type, $title, $message, $data);
            $count++;
        }

        return $count;
    }

    /**
     * Kirim notifikasi ke seluruh pengguna aktif dalam perusahaan (misalnya pengumuman payroll).
     */
    public function notifyCompanyUsers(
        int $companyId,
        string $type,
        string $title,
        string $message,
        ?array $data = null,
        ?int $exceptUserId = null
    ): int {
        $users = User::where('id_companies', $companyId)
            ->where('is_active', true)
            ->when($exceptUserId, fn ($q) => $q->where('id_users', '!=', $exceptUserId))
            ->get();

        $count = 0;
        foreach ($users as $user) {
            $this->send($companyId, $user->id_users, $type, $title, $message, $data);
            $count++;
        }

        return $count;
    }

    /**
     * Ambil daftar notifikasi untuk pengguna yang sedang aktif.
     */
    public function getUserNotifications(User $user, ?bool $unreadOnly = false, int $perPage = 20): LengthAwarePaginator
    {
        $query = Notification::where('id_companies', $user->id_companies)
            ->where('id_users', $user->id_users)
            ->orderBy('created_at', 'desc');

        if ($unreadOnly) {
            $query->where('is_read', false);
        }

        return $query->paginate($perPage);
    }

    /**
     * Ambil jumlah notifikasi yang belum dibaca.
     */
    public function getUnreadCount(User $user): int
    {
        return Notification::where('id_companies', $user->id_companies)
            ->where('id_users', $user->id_users)
            ->where('is_read', false)
            ->count();
    }

    /**
     * Tandai satu notifikasi sebagai telah dibaca.
     */
    public function markAsRead(int $idNotification, User $user): ?Notification
    {
        $notification = Notification::where('id_companies', $user->id_companies)
            ->where('id_users', $user->id_users)
            ->find($idNotification);

        if (! $notification) {
            return null;
        }

        if (! $notification->is_read) {
            $notification->update([
                'is_read' => true,
                'read_at' => Carbon::now(),
            ]);
        }

        return $notification;
    }

    /**
     * Tandai seluruh notifikasi milik pengguna sebagai telah dibaca.
     */
    public function markAllAsRead(User $user): int
    {
        return Notification::where('id_companies', $user->id_companies)
            ->where('id_users', $user->id_users)
            ->where('is_read', false)
            ->update([
                'is_read' => true,
                'read_at' => Carbon::now(),
            ]);
    }

    /**
     * Hapus satu notifikasi milik pengguna.
     */
    public function deleteNotification(int $idNotification, User $user): bool
    {
        $notification = Notification::where('id_companies', $user->id_companies)
            ->where('id_users', $user->id_users)
            ->find($idNotification);

        if (! $notification) {
            return false;
        }

        return (bool) $notification->delete();
    }
}
