"use client";

import { useEffect, useState } from "react";
import GreetForm from "./components/GreetForm";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

type HelloResponse = {
  message: string;
};

export default function Home() {
  const [message, setMessage] = useState<string | null>(null);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const controller = new AbortController();

    fetch(`${API_BASE_URL}/api/hello/`, { signal: controller.signal })
      .then(async (res) => {
        if (!res.ok) throw new Error(`HTTP ${res.status}`);
        const data: HelloResponse = await res.json();
        setMessage(data.message);
      })
      .catch((err: unknown) => {
        if (err instanceof DOMException && err.name === "AbortError") return;
        setError(err instanceof Error ? err.message : String(err));
      });

    return () => controller.abort();
  }, []);

  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-10 bg-zinc-50 p-8 font-sans dark:bg-black">
      <h1 className="text-3xl font-semibold text-black dark:text-zinc-50">
        Django × Next.js
      </h1>

      {/* GET /api/hello/ */}
      <section className="flex w-full max-w-md flex-col gap-2">
        <h2 className="text-xl font-semibold text-black dark:text-zinc-50">
          GET /api/hello/
        </h2>
        <div
          data-testid="hello-message"
          className="rounded-xl border border-zinc-200 bg-white px-6 py-4 text-lg font-medium text-zinc-900 shadow-sm dark:border-zinc-800 dark:bg-zinc-900 dark:text-zinc-50"
        >
          {error ? (
            <span className="text-red-600">Error: {error}</span>
          ) : message ? (
            message
          ) : (
            <span className="text-zinc-400">Loading…</span>
          )}
        </div>
      </section>

      <hr className="w-full max-w-md border-zinc-200 dark:border-zinc-800" />

      {/* POST /api/greet/ */}
      <GreetForm />
    </main>
  );
}
