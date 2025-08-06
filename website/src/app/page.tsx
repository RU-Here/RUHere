"use client";

import { useState } from "react";

export default function Home() {
  const [email, setEmail] = useState("");
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [message, setMessage] = useState("");

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
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
    }

    setIsSubmitting(false);
  };

  return (
    <div className="min-h-screen bg-[#1b1b1b]">
      <div className="container mx-auto px-4 py-16">
        <div className="max-w-4xl mx-auto text-center">
          <div className="bg-zinc-800 rounded-2xl shadow-xl p-8 md:p-12 max-w-2xl mx-auto">
            <p className="text-white mb-8">
              Join our waitlist to get early access to RuHere.
            </p>

            <form onSubmit={handleSubmit} className="space-y-4">
              <div className="flex flex-col md:flex-row gap-4">
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="Enter your email address"
                  required
                  className="flex-1 px-4 py-3 border border-gray-300 rounded-lg text-white focus:outline-none focus:ring-2 focus:ring-[#ff4540] focus:border-transparent text-gray-900"
                />
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-8 py-3 bg-[#ff4540] text-white font-semibold rounded-lg hover:bg-[#b3302d] focus:outline-none focus:ring-2 focus:ring-[#ff4540] focus:ring-offset-2 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                >
                  {isSubmitting ? "Joining..." : "Join Waitlist"}
                </button>
              </div>
            </form>

            {message && (
              <div
                className={`mt-4 p-3 rounded-lg ${
                  message.includes("Thanks")
                    ? "bg-green-100 text-green-800"
                    : "bg-red-100 text-red-800"
                }`}
              >
                {message}
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
