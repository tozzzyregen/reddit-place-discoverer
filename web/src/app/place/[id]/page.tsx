"use client";

import { useEffect, useState } from "react";
import { useParams, useRouter } from "next/navigation";
import { ArrowLeft, ExternalLink, MapPin, Star } from "lucide-react";

interface PlaceDetail {
  id: string;
  name: string;
  description: string;
  formatted_address?: string;
  google_place_id?: string;
  photo_reference?: string;
  rating?: number;
  user_ratings_total?: number;
  source_links?: string[];
  last_updated?: string;
}

export default function PlaceDetailPage() {
  const params = useParams();
  const router = useRouter();
  const [place, setPlace] = useState<PlaceDetail | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const placeId = params.id as string;

  useEffect(() => {
    const fetchPlace = async () => {
      if (!placeId) return;

      setIsLoading(true);
      setError(null);

      try {
        const response = await fetch(
          `${process.env.NEXT_PUBLIC_API_URL}/research/places/${placeId}`
        );

        if (!response.ok) {
          throw new Error("Place not found");
        }

        const data: PlaceDetail = await response.json();
        setPlace(data);
      } catch (err) {
        console.error("Error fetching place:", err);
        setError("Failed to load place details");
      } finally {
        setIsLoading(false);
      }
    };

    fetchPlace();
  }, [placeId]);

  const photoUrl = place?.photo_reference
    ? `${process.env.NEXT_PUBLIC_API_URL}/search/photo?reference=${place.photo_reference}`
    : null;

  if (isLoading) {
    return (
      <div className="min-h-screen bg-black text-white flex items-center justify-center">
        <div className="text-center">
          <div className="animate-pulse text-xl text-gray-400">
            Loading vibe details...
          </div>
          <div className="mt-4 flex justify-center space-x-2">
            <div className="w-3 h-3 bg-orange-500 rounded-full animate-bounce" style={{ animationDelay: "0ms" }}></div>
            <div className="w-3 h-3 bg-red-500 rounded-full animate-bounce" style={{ animationDelay: "150ms" }}></div>
            <div className="w-3 h-3 bg-pink-500 rounded-full animate-bounce" style={{ animationDelay: "300ms" }}></div>
          </div>
        </div>
      </div>
    );
  }

  if (error || !place) {
    return (
      <div className="min-h-screen bg-black text-white flex items-center justify-center">
        <div className="text-center">
          <p className="text-xl text-red-400">{error || "Place not found"}</p>
          <button
            onClick={() => router.back()}
            className="mt-6 px-6 py-2 bg-gray-800 rounded-full hover:bg-gray-700 transition-colors"
          >
            Go Back
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-black text-white">
      {/* Hero Image */}
      <div className="relative h-[400px] w-full">
        {photoUrl ? (
          <img
            src={photoUrl}
            alt={place.name}
            className="w-full h-full object-cover"
          />
        ) : (
          <div className="w-full h-full bg-gradient-to-br from-orange-600 via-red-600 to-pink-600" />
        )}
        
        {/* Gradient Overlay */}
        <div className="absolute inset-0 bg-gradient-to-t from-black via-black/50 to-transparent" />

        {/* Back Button */}
        <button
          onClick={() => router.back()}
          className="absolute top-6 left-6 flex items-center gap-2 px-4 py-2 bg-black/50 backdrop-blur-sm rounded-full hover:bg-black/70 transition-colors"
        >
          <ArrowLeft size={20} />
          <span>Back</span>
        </button>

        {/* Flash Badge */}
        <div className="absolute top-6 right-6">
          <span className="px-3 py-1 bg-yellow-500/20 text-yellow-400 border border-yellow-500/30 rounded-full text-sm font-medium">
            ⚡ Instant Vibe
          </span>
        </div>
      </div>

      {/* Content Container - Overlapping */}
      <div className="relative -mt-24 px-6 pb-20">
        <div className="max-w-4xl mx-auto">
          {/* Title Card */}
          <div className="bg-gray-900 rounded-2xl p-8 shadow-xl">
            <h1 className="text-4xl font-bold text-white">
              {place.name}
            </h1>

            {/* Address & Rating */}
            <div className="mt-4 flex flex-wrap items-center gap-4 text-gray-400">
              {place.formatted_address && (
                <div className="flex items-center gap-2">
                  <MapPin size={16} />
                  <span className="text-sm">{place.formatted_address}</span>
                </div>
              )}
              {place.rating && (
                <div className="flex items-center gap-1">
                  <Star size={16} className="text-amber-400 fill-amber-400" />
                  <span className="text-white font-medium">{place.rating}</span>
                  {place.user_ratings_total && (
                    <span className="text-gray-500">
                      ({place.user_ratings_total.toLocaleString()} reviews)
                    </span>
                  )}
                </div>
              )}
            </div>

            {/* Vibe Summary */}
            {place.description && (
              <blockquote className="mt-8 pl-6 border-l-4 border-orange-500">
                <p className="text-lg text-gray-300 italic leading-relaxed">
                  &ldquo;{place.description}&rdquo;
                </p>
              </blockquote>
            )}

            {/* Source Links */}
            {place.source_links && place.source_links.length > 0 && (
              <div className="mt-10">
                <h3 className="text-sm font-semibold text-gray-500 uppercase tracking-wider mb-4">
                  Sources & References
                </h3>
                <div className="flex flex-wrap gap-3">
                  {place.source_links.map((link, index) => (
                    <a
                      key={index}
                      href={link}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center gap-2 px-4 py-2 bg-gray-800 rounded-lg hover:bg-gray-700 transition-colors text-sm text-blue-400"
                    >
                      <ExternalLink size={14} />
                      Read Source {index + 1}
                    </a>
                  ))}
                </div>
              </div>
            )}

            {/* Last Updated */}
            {place.last_updated && (
              <p className="mt-8 text-xs text-gray-600">
                Last updated: {new Date(place.last_updated).toLocaleDateString()}
              </p>
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

