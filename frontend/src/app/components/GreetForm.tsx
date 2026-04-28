"use client";

import { FormEvent, useState } from "react";

const API_BASE_URL =
  process.env.NEXT_PUBLIC_API_BASE_URL ?? "http://localhost:8000";

type GreetResponse = {
  message: string;
  name: string;
};

type State =
  | { status: "idle" }
  | { status: "loading" }
  | { status: "success"; data: GreetResponse }
  | { status: "error"; message: string };

export default function GreetForm() {
  const [name, setName] = useState("");
  const [state, setState] = useState<State>({ status: "idle" });

  async function handleSubmit(e: FormEvent<HTMLFormElement>) {
    e.preventDefault();
    if (!name.trim()) return;

    setState({ status: "loading" });

    try {
      const res = await fetch(`${API_BASE_URL}/api/greet/`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ name: name.trim() }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        const detail =
          typeof err === "object" && err !== null && "name" in err
            ? (err as { name: string[] }).name[0]
            : `HTTP ${res.status}`;
        setState({ status: "error", message: detail });
        return;
      }

      const data: GreetResponse = await res.json();
      setState({ status: "success", data });
    } catch (err) {
      setState({
        status: "error",
        message: err instanceof Error ? err.message : String(err),
      });
    }
  }

  return (
    <section className="flex w-full max-w-md flex-col gap-4">
      <h2 className="text-xl font-semibold text-black dark:text-zinc-50">
        POST /api/greet/
      </h2>

      <form onSubmit={handleSubmit} className="flex gap-2">
        <input
          type="text"
          value={name}
          onChange={(e) => setName(e.target.value)}
          placeholder="名前を入力"
          maxLength={100}
          className="flex-1 rounded-lg border border-zinc-300 bg-white px-4 py-2 text-sm text-zinc-900 placeholder-zinc-400 focus:outline-none focus:ring-2 focus:ring-zinc-400 dark:border-zinc-700 dark:bg-zinc-900 dark:text-zinc-50 dark:placeholder-zinc-500"
        />
        <button
          type="submit"
          disabled={state.status === "loading" || !name.trim()}
          className="rounded-lg bg-zinc-900 px-4 py-2 text-sm font-medium text-white transition-colors hover:bg-zinc-700 disabled:cursor-not-allowed disabled:opacity-50 dark:bg-zinc-50 dark:text-zinc-900 dark:hover:bg-zinc-200"
        >
          {state.status === "loading" ? "送信中…" : "送信"}
        </button>
      </form>

      {state.status === "success" && (
        <div className="rounded-xl border border-zinc-200 bg-white px-6 py-4 shadow-sm dark:border-zinc-800 dark:bg-zinc-900">
          <p className="text-xs text-zinc-400">message</p>
          <p className="mt-1 text-lg font-medium text-zinc-900 dark:text-zinc-50">
            {state.data.message}
          </p>
        </div>
      )}

      {state.status === "error" && (
        <p className="text-sm text-red-600">Error: {state.message}</p>
      )}
    </section>
  );
}
