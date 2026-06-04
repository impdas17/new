"use client";

import { useState } from "react";
import { createClient } from "@/lib/supabase/client";

export default function Login() {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [message, setMessage] = useState<string | null>(null);

  const supabase = createClient();

  const handleLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setMessage(null);

    const { error } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (error) {
      setError(error.message);
      return;
    }

    // Refresh to let middleware handle redirect
    window.location.href = "/";
  };

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setMessage(null);

    const { error } = await supabase.auth.signUp({
      email,
      password,
    });

    if (error) {
      setError(error.message);
      return;
    }

    setMessage("Check your email for the confirmation link.");
  };

  return (
    <div className="flex flex-col items-center justify-center min-h-screen bg-slate-50 text-slate-900">
      <div className="w-full max-w-md p-8 space-y-6 bg-white rounded-xl shadow-md border border-slate-200">
        <h1 className="text-2xl font-bold text-center">KnowledgeOS AI</h1>
        <p className="text-sm text-center text-slate-500">Sign in to your account</p>

        {error && <div className="p-3 text-sm text-red-500 bg-red-50 rounded-md">{error}</div>}
        {message && <div className="p-3 text-sm text-green-500 bg-green-50 rounded-md">{message}</div>}

        <form className="space-y-4" onSubmit={handleLogin}>
          <div>
            <label className="block text-sm font-medium mb-1">Email</label>
            <input
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              required
              className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-slate-400"
            />
          </div>
          <div>
            <label className="block text-sm font-medium mb-1">Password</label>
            <input
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              required
              className="w-full px-3 py-2 border rounded-md focus:outline-none focus:ring-2 focus:ring-slate-400"
            />
          </div>

          <div className="flex gap-4">
            <button
              type="submit"
              className="w-full py-2 text-white bg-slate-900 rounded-md hover:bg-slate-800 transition"
            >
              Sign In
            </button>
            <button
              type="button"
              onClick={handleSignUp}
              className="w-full py-2 text-slate-900 bg-slate-100 rounded-md hover:bg-slate-200 transition"
            >
              Sign Up
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}
