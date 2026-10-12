"use client";

import { useEffect } from "react";
import { useRouter } from "next/navigation";
import CompanyProfilePage from "../company-profile/page";

export default function CompaniesRedirectPage() {
  const router = useRouter();

  useEffect(() => {
    router.replace("/company-profile");
  }, [router]);

  return <CompanyProfilePage />;
}
