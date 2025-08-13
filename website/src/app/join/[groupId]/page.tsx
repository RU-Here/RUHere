"use client";

import { useParams, useRouter } from "next/navigation";
import { useEffect, useState } from "react";

interface GroupInfo {
  name: string;
  emoji: string;
  admin: string;
}

export default function JoinGroupPage() {
  const params = useParams();
  const router = useRouter();
  const groupId = params.groupId as string;

  const [groupInfo, setGroupInfo] = useState<GroupInfo | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!groupId) return;

    // Fetch group information
    const fetchGroupInfo = async () => {
      try {
        const response = await fetch(
          `https://ru-here-api.vercel.app/api/public/getGroup`,
          {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
            },
            body: JSON.stringify({ groupId }),
          }
        );

        if (response.ok) {
          const data = await response.json();
          setGroupInfo(data.group);
        } else {
          setError("Group not found or invalid");
        }
      } catch {
        setError("Failed to load group information");
      } finally {
        setIsLoading(false);
      }
    };

    fetchGroupInfo();
  }, [groupId]);

  const handleOpenApp = () => {
    const customSchemeUrl = `ruhere://join/${groupId}`;
    let appOpened = false;

    // Track if user navigates away (app opened successfully)
    const handleBlur = () => {
      appOpened = true;
      window.removeEventListener("blur", handleBlur);
    };

    const handleVisibilityChange = () => {
      if (document.hidden) {
        appOpened = true;
        document.removeEventListener(
          "visibilitychange",
          handleVisibilityChange
        );
      }
    };

    window.addEventListener("blur", handleBlur);
    document.addEventListener("visibilitychange", handleVisibilityChange);

    // Try different methods based on platform
    const userAgent = navigator.userAgent.toLowerCase();
    const isIOS = userAgent.includes("iphone") || userAgent.includes("ipad");
    const isAndroid = userAgent.includes("android");

    if (isIOS) {
      // For iOS, try direct navigation first
      try {
        window.location.href = customSchemeUrl;
      } catch {
        console.log("Direct navigation failed, trying iframe method");
        // Fallback to iframe method
        const iframe = document.createElement("iframe");
        iframe.style.display = "none";
        iframe.src = customSchemeUrl;
        document.body.appendChild(iframe);
        setTimeout(() => {
          if (document.body.contains(iframe)) {
            document.body.removeChild(iframe);
          }
        }, 1000);
      }
    } else if (isAndroid) {
      // For Android, try intent URL first, then fallback to custom scheme
      const intentUrl = `intent://join/${groupId}#Intent;scheme=ruhere;package=com.example.testapp;end`;
      try {
        window.location.href = intentUrl;
      } catch {
        window.location.href = customSchemeUrl;
      }
    } else {
      // For desktop/other platforms, try iframe method
      const iframe = document.createElement("iframe");
      iframe.style.display = "none";
      iframe.src = customSchemeUrl;
      document.body.appendChild(iframe);
      setTimeout(() => {
        if (document.body.contains(iframe)) {
          document.body.removeChild(iframe);
        }
      }, 1000);
    }

    // Fallback: redirect to app store after a delay if the app doesn't open
    setTimeout(() => {
      window.removeEventListener("blur", handleBlur);
      document.removeEventListener("visibilitychange", handleVisibilityChange);

      if (!appOpened) {
        if (isIOS) {
          // TODO: replace with actual App Store URL when available
          window.open("https://apps.apple.com/app/ruhere", "_blank");
        } else if (isAndroid) {
          // TODO: replace with actual Play Store URL when available
          window.open(
            "https://play.google.com/store/apps/details?id=com.example.testapp",
            "_blank"
          );
        } else {
          alert("Please install the RUHere mobile app to join this group.");
        }
      }
    }, 3000);
  };

  if (isLoading) {
    return (
      <div className="min-h-screen bg-[#1b1b1b] flex items-center justify-center">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-[#ff4540] mx-auto mb-4"></div>
          <p className="text-white">Loading group information...</p>
        </div>
      </div>
    );
  }

  if (error || !groupInfo) {
    return (
      <div className="min-h-screen bg-[#1b1b1b] flex items-center justify-center">
        <div className="max-w-md mx-auto text-center px-4">
          <div className="bg-zinc-800 rounded-2xl shadow-xl p-8">
            <div className="text-6xl mb-4">❌</div>
            <h1 className="text-2xl font-bold text-white mb-4">
              Group Not Found
            </h1>
            <p className="text-gray-300 mb-6">
              The group you&apos;re trying to join either doesn&apos;t exist or
              the link is invalid.
            </p>
            <button
              onClick={() => router.push("/")}
              className="px-6 py-3 bg-[#ff4540] text-white font-semibold rounded-lg hover:bg-[#b3302d] transition-colors"
            >
              Go to Home
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-[#1b1b1b] flex items-center justify-center">
      <div className="max-w-md mx-auto text-center px-4">
        <div className="bg-zinc-800 rounded-2xl shadow-xl p-8">
          <div className="text-6xl mb-4">{groupInfo.emoji}</div>
          <h1 className="text-2xl font-bold text-white mb-2">
            Join {groupInfo.name}
          </h1>
          <p className="text-gray-300 mb-6">
            You&apos;ve been invited to join this group! Open the RUHere app to
            continue.
          </p>

          <div className="space-y-4">
            <button
              onClick={handleOpenApp}
              className="w-full px-6 py-3 bg-[#ff4540] text-white font-semibold rounded-lg hover:bg-[#b3302d] focus:outline-none focus:ring-2 focus:ring-[#ff4540] focus:ring-offset-2 transition-colors"
            >
              Join Group in App
            </button>

            <p className="text-sm text-gray-400">
              This will open the RUHere app or redirect you to download it if
              not installed.
            </p>
          </div>

          <div className="mt-8 pt-6 border-t border-gray-700">
            <p className="text-xs text-gray-500">Group ID: {groupId}</p>
          </div>
        </div>
      </div>
    </div>
  );
}
