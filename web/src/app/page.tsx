"use client";

import { useState } from "react";

interface SearchResult {
  title: string;
  text: string;
  url: string;
  source_query?: string;
}

interface ResearchResponse {
  query: string;
  hunter_queries: string[];
  results: SearchResult[];
  total_results: number;
  source_type?: "memory" | "live";
}

export default function Home() {
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<SearchResult[]>([]);
  const [sourceType, setSourceType] = useState<"memory" | "live" | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const handleSearch = async () => {
    if (!query.trim()) return;

    setIsLoading(true);
    setResults([]);
    setSourceType(null);

    try {
      const response = await fetch(
        `${process.env.NEXT_PUBLIC_API_URL}/research`,
        {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
          },
          body: JSON.stringify({ query }),
        }
      );

      if (!response.ok) {
        throw new Error("Search failed");
      }

      const data: ResearchResponse = await response.json();
      setResults(data.results);
      setSourceType(data.source_type || null);
    } catch (error) {
      console.error("Search error:", error);
    } finally {
      setIsLoading(false);
    }
  };

  const handleKeyDown = (e: React.KeyboardEvent<HTMLInputElement>) => {
    if (e.key === "Enter") {
      handleSearch();
    }
  };

  return (
    <div className="min-h-screen bg-black text-white">
      {/* Hero Section */}
      <div className="flex flex-col items-center pt-20 pb-12 px-6">
        <h1 className="text-6xl font-bold bg-gradient-to-r from-orange-500 via-red-500 to-pink-500 bg-clip-text text-transparent">
          Vibe Check
        </h1>
        <p className="mt-4 text-xl text-gray-400">
          Don&apos;t just travel. Know the vibe.
        </p>

        {/* Search Input */}
        <div className="mt-10 w-full max-w-2xl">
          <input
            type="text"
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            onKeyDown={handleKeyDown}
            placeholder="Where do you want to feel the vibe? (e.g. Jazz in Tokyo)"
            className="w-full p-4 rounded-full bg-gray-900 border border-gray-700 text-white placeholder-gray-500 focus:outline-none focus:border-orange-500 transition-colors"
          />
        </div>
      </div>

      {/* Loading State */}
      {isLoading && (
        <div className="flex flex-col items-center py-12">
          <div className="animate-pulse text-xl text-gray-400">
            Searching the deep web...
          </div>
          <div className="mt-4 flex space-x-2">
            <div className="w-3 h-3 bg-orange-500 rounded-full animate-bounce" style={{ animationDelay: "0ms" }}></div>
            <div className="w-3 h-3 bg-red-500 rounded-full animate-bounce" style={{ animationDelay: "150ms" }}></div>
            <div className="w-3 h-3 bg-pink-500 rounded-full animate-bounce" style={{ animationDelay: "300ms" }}></div>
          </div>
        </div>
      )}

      {/* Results Grid */}
      {!isLoading && results.length > 0 && (
        <div className="px-6 pb-20">
          <div className="text-center mb-8">
            <p className="text-gray-500">
              Found {results.length} sources
            </p>
            {sourceType && (
              <span className={`inline-block mt-2 px-3 py-1 rounded-full text-sm font-medium ${
                sourceType === "memory" 
                  ? "bg-yellow-500/20 text-yellow-400 border border-yellow-500/30" 
                  : "bg-cyan-500/20 text-cyan-400 border border-cyan-500/30"
              }`}>
                {sourceType === "memory" ? "⚡ Instant Vibe" : "🌐 Fresh Discovery"}
              </span>
            )}
          </div>
          <div className="max-w-6xl mx-auto grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            {results.map((result, index) => (
              <div
                key={index}
                className="relative bg-gray-800 rounded-xl p-6 hover:bg-gray-700 transition-colors group cursor-pointer"
              >
                {/* Source Badge */}
                {sourceType && (
                  <div className={`absolute top-3 right-3 px-2 py-1 rounded text-xs font-medium ${
                    sourceType === "memory"
                      ? "bg-yellow-500/20 text-yellow-400"
                      : "bg-cyan-500/20 text-cyan-400"
                  }`}>
                    {sourceType === "memory" ? "⚡" : "🌐"}
                  </div>
                )}
                
                <h3 className="text-xl font-bold text-white line-clamp-2 pr-8 group-hover:text-orange-400 transition-colors">
                  {result.title || "Untitled"}
                </h3>
                <p className="mt-3 text-gray-400 text-sm line-clamp-3">
                  {result.text || "No description available."}
                </p>
                {result.url && (
                  <a
                    href={result.url}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="mt-4 inline-block text-blue-400 text-sm hover:text-blue-300 transition-colors"
                    onClick={(e) => e.stopPropagation()}
                  >
                    Read Source →
                  </a>
                )}
              </div>
            ))}
          </div>
        </div>
      )}

      {/* Empty State */}
      {!isLoading && results.length === 0 && query === "" && (
        <div className="text-center py-12 text-gray-600">
          <p>Enter a destination or vibe to start exploring</p>
        </div>
      )}
    </div>
  );
}
