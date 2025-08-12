"use client";

import { useState } from "react";

export default function Home() {
  const [email, setEmail] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (
      !email.endsWith("@rutgers.edu") &&
      !email.endsWith("@scarletmail.rutgers.edu")
    ) {
      setMessage("Please use your Rutgers email address to join the waitlist.");
      return;
    }

    setIsSubmitting(true);
    setMessage("");

    try {
      const response = await fetch(
        "https://ru-here.vercel.app/api/geofence/joinWaitlist",
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "x-api-key": process.env.NEXT_PUBLIC_API_KEY || "",
          },
          body: JSON.stringify({ email }),
        }
      );

      if (response.ok) {
        setMessage("Thanks for joining our waitlist! We'll be in touch soon.");
        setEmail("");
      } else {
        setMessage("Something went wrong. Please try again.");
      }
    } catch (error) {
      setMessage("Something went wrong. Please try again.");
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <div className="relative min-h-screen bg-zinc-900 text-white">
      <div className="mx-auto max-w-7xl px-6 py-16 lg:px-8 lg:py-24">
        <div className="grid items-center gap-12 lg:grid-cols-2">
          <div>
            <div className="mb-8 inline-flex items-center gap-3 rounded-full border border-zinc-700 bg-zinc-800 px-4 py-2 shadow-sm backdrop-blur">
              <img
                src="/logo.png"
                alt="RuHere"
                className="h-8 w-8 rounded-md"
              />
              <span className="text-lg font-semibold text-white">RuHere</span>
            </div>

            <h1 className="text-4xl font-extrabold tracking-tight text-white sm:text-5xl lg:text-6xl">
              No more missed connections
            </h1>

            <p className="mt-6 max-w-xl text-lg text-zinc-300">
              Find your friends wherever you go.
            </p>

            <form onSubmit={handleSubmit} className="mt-8 max-w-xl">
              <div className="flex flex-col gap-3 sm:flex-row">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Enter your email"
                  required
                  className="flex-1 rounded-xl border border-zinc-600 bg-zinc-800 px-4 py-3 text-white placeholder-zinc-400 shadow-sm outline-none transition focus:border-violet-400 focus:ring-4 focus:ring-violet-100"
                />
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="rounded-xl bg-violet-600 px-6 py-3 font-semibold cursor-pointer text-white shadow-sm transition hover:bg-violet-700 focus:ring-4 focus:ring-violet-200 disabled:cursor-not-allowed disabled:opacity-60"
                >
                  {isSubmitting ? "Joining…" : "Join waitlist"}
                </button>
              </div>
            </form>

            {message && (
              <p
                className={`mt-4 text-sm ${
                  message.includes("Thanks")
                    ? "text-emerald-400"
                    : "text-rose-400"
                }`}
              >
                {message}
              </p>
            )}
            <div className="mt-4 text-sm text-zinc-400 w-fit">
              <a
                href="https://www.instagram.com/ruhere.app/"
                className="flex items-center gap-2 hover:text-zinc-200 hover:underline transition-colors"
              >
                <span className="text-sm text-zinc-400">
                  Follow @ruhere.app for updates
                </span>
                <svg
                  xmlns="http://www.w3.org/2000/svg"
                  className="h-4 w-4 fill-none stroke-current"
                  viewBox="0 0 24 24"
                  strokeWidth="2"
                >
                  {" "}
                  <path
                    strokeLinecap="round"
                    strokeLinejoin="round"
                    d="M10 6H6a2 2 0 00-2 2v10a2 2 0 002 2h10a2 2 0 002-2v-4M14 4h6m0 0v6m0-6L10 14"
                  ></path>{" "}
                </svg>
              </a>
            </div>
          </div>
          <div className="relative hidden lg:block">
            <img
              src="/notification.svg"
              alt="Notification illustration"
              className="w-full h-auto"
            />
          </div>
        </div>
      </div>
    </div>
  );
}
