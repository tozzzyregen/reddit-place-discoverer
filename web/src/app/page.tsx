export default function Home() {
  return (
    <div className="min-h-screen bg-black text-white flex flex-col items-center justify-center">
      {/* Hero Section */}
      <div className="text-center px-6">
        <h1 className="text-6xl font-bold bg-gradient-to-r from-orange-500 via-red-500 to-pink-500 bg-clip-text text-transparent">
          Vibe Check
        </h1>
        <p className="mt-6 text-xl text-gray-400 max-w-md mx-auto">
          Don&apos;t just travel. Know the vibe.
        </p>
        <button className="mt-8 px-8 py-3 bg-white text-black font-semibold rounded-full hover:bg-gray-200 transition-colors">
          Start Searching
        </button>
      </div>
    </div>
  );
}
