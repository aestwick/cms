import React, { useState, useEffect, useRef, useCallback } from 'react';

// Live stream player component
const LivePlayer = ({ isVisible }) => {
  const audioRef = useRef(null);
  const [isPlaying, setIsPlaying] = useState(false);
  const [volume, setVolume] = useState(0.8);
  
  const togglePlay = () => {
    if (!audioRef.current) return;
    
    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      audioRef.current.play().then(() => {
        setIsPlaying(true);
      }).catch((e) => {
        console.log('Playback failed:', e);
      });
    }
  };
  
  const handleVolumeChange = (e) => {
    const newVolume = parseFloat(e.target.value);
    setVolume(newVolume);
    if (audioRef.current) {
      audioRef.current.volume = newVolume;
    }
  };
  
  // Stop audio when player is hidden (tuned away from 90.7)
  useEffect(() => {
    if (!isVisible && isPlaying && audioRef.current) {
      audioRef.current.pause();
      setIsPlaying(false);
    }
  }, [isVisible, isPlaying]);
  
  // Set initial volume
  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume;
    }
  }, []);
  
  return (
    <div
      className="transition-all duration-500"
      style={{
        opacity: isVisible ? 1 : 0,
        transform: isVisible ? 'translateY(0)' : 'translateY(16px)',
        pointerEvents: isVisible ? 'auto' : 'none',
      }}
    >
      <audio
        ref={audioRef}
        src="https://streams.pacifica.org:9000/kpfk_128"
        preload="none"
      />
      
      <div 
        className="mx-auto max-w-sm"
        style={{ border: '3px solid #1a1a1a', backgroundColor: '#fff' }}
      >
        {/* Main player row */}
        <div className="flex items-center gap-4 px-4 py-3">
          {/* Play/Pause button */}
          <button
            onClick={togglePlay}
            className="flex-shrink-0 flex items-center justify-center transition-opacity hover:opacity-80"
            style={{
              width: '44px',
              height: '44px',
              backgroundColor: '#c41e3a',
              border: 'none',
              cursor: 'pointer',
            }}
            aria-label={isPlaying ? 'Stop' : 'Play'}
          >
            {isPlaying ? (
              <svg width="18" height="18" viewBox="0 0 24 24" fill="white">
                <rect x="4" y="4" width="16" height="16" />
              </svg>
            ) : (
              <svg width="18" height="18" viewBox="0 0 24 24" fill="white">
                <polygon points="5,3 19,12 5,21" />
              </svg>
            )}
          </button>
          
          {/* Station info */}
          <div className="flex-1 min-w-0">
            <div 
              className="font-mono text-xs font-bold uppercase flex items-center gap-2"
              style={{ color: isPlaying ? '#c41e3a' : '#555', letterSpacing: '0.5px' }}
            >
              <span 
                className="inline-block w-2 h-2"
                style={{ 
                  backgroundColor: isPlaying ? '#c41e3a' : '#999',
                  animation: isPlaying ? 'pulse 2s infinite' : 'none',
                }}
              />
              {isPlaying ? 'ON AIR' : 'READY'}
            </div>
            <div 
              className="font-bold uppercase text-sm tracking-tight mt-0.5 truncate"
              style={{ 
                fontFamily: 'Helvetica Neue, Helvetica, Arial, sans-serif',
                color: '#1a1a1a',
              }}
            >
              KPFK 90.7 FM
            </div>
          </div>
          
          {/* Volume control */}
          <div className="flex items-center gap-2 flex-shrink-0">
            <svg 
              width="16" 
              height="16" 
              viewBox="0 0 24 24" 
              fill="none" 
              stroke={volume === 0 ? '#999' : '#1a1a1a'}
              strokeWidth="2"
            >
              {volume === 0 ? (
                <>
                  <polygon points="11,5 6,9 2,9 2,15 6,15 11,19" fill="currentColor" />
                  <line x1="23" y1="9" x2="17" y2="15" />
                  <line x1="17" y1="9" x2="23" y2="15" />
                </>
              ) : (
                <>
                  <polygon points="11,5 6,9 2,9 2,15 6,15 11,19" fill="#1a1a1a" />
                  {volume > 0.3 && <path d="M15.54,8.46a5,5,0,0,1,0,7.07" />}
                  {volume > 0.6 && <path d="M19.07,4.93a10,10,0,0,1,0,14.14" />}
                </>
              )}
            </svg>
            <input
              type="range"
              min="0"
              max="1"
              step="0.05"
              value={volume}
              onChange={handleVolumeChange}
              className="volume-slider"
              style={{
                width: '60px',
                height: '3px',
                appearance: 'none',
                background: `linear-gradient(to right, #1a1a1a ${volume * 100}%, #ccc ${volume * 100}%)`,
                cursor: 'pointer',
              }}
              aria-label="Volume"
            />
          </div>
        </div>
      </div>
      
      <style>{`
        @keyframes pulse {
          0%, 100% { opacity: 1; }
          50% { opacity: 0.5; }
        }
        .volume-slider::-webkit-slider-thumb {
          appearance: none;
          width: 12px;
          height: 12px;
          background: #1a1a1a;
          cursor: pointer;
        }
        .volume-slider::-moz-range-thumb {
          width: 12px;
          height: 12px;
          background: #1a1a1a;
          border: none;
          cursor: pointer;
        }
      `}</style>
    </div>
  );
};

// Halftone/newsprint texture overlay instead of TV static
const NewsprintTexture = ({ opacity = 0.04 }) => {
  return (
    <div 
      className="fixed inset-0 pointer-events-none"
      style={{
        opacity,
        backgroundImage: `radial-gradient(circle, #1a1a1a 1px, transparent 1px)`,
        backgroundSize: '4px 4px',
      }}
    />
  );
};

// Waveform - more editorial/diagrammatic style
const Waveform = ({ signalStrength, isSearching }) => {
  const [points, setPoints] = useState([]);
  
  useEffect(() => {
    const interval = setInterval(() => {
      const newPoints = Array.from({ length: 48 }, (_, i) => {
        if (isSearching) {
          return Math.sin(i * 0.4 + Date.now() * 0.008) * 25 + 
                 (Math.random() - 0.5) * 30;
        } else if (signalStrength > 0.8) {
          return Math.sin(i * 0.25 + Date.now() * 0.004) * 18;
        } else {
          return (Math.random() - 0.5) * 50 * (1 - signalStrength);
        }
      });
      setPoints(newPoints);
    }, 60);
    
    return () => clearInterval(interval);
  }, [signalStrength, isSearching]);
  
  const pathD = points.length > 0 
    ? `M 0 40 ${points.map((p, i) => `L ${i * (320 / 48)} ${40 + p}`).join(' ')}`
    : 'M 0 40 L 320 40';
  
  return (
    <div className="border-3 border-black p-4 bg-white">
      <svg viewBox="0 0 320 80" className="w-full h-16">
        <path
          d={pathD}
          fill="none"
          stroke="#c41e3a"
          strokeWidth="2"
        />
        {/* Baseline */}
        <line x1="0" y1="40" x2="320" y2="40" stroke="#999" strokeWidth="1" strokeDasharray="4 4" />
      </svg>
    </div>
  );
};

// Interactive frequency dial - editorial/infographic style
const FrequencyDial = ({ frequency, onChange, isSearching }) => {
  const dialRef = useRef(null);
  const [isDragging, setIsDragging] = useState(false);
  
  // Convert frequency to percentage position (0-100)
  const freqToPercent = (freq) => ((freq - 88) / (108 - 88)) * 100;
  
  const handleInteraction = useCallback((clientX) => {
    if (!dialRef.current) return;
    const rect = dialRef.current.getBoundingClientRect();
    const padding = 24;
    const trackWidth = rect.width - (padding * 2);
    const x = clientX - rect.left - padding;
    const percent = Math.max(0, Math.min(1, x / trackWidth));
    let freq = 88 + percent * 20;
    
    // STICKY ZONE: Snap to 90.7 if within 1.0 FM (makes it much easier to hit)
    if (Math.abs(freq - 90.7) < 1.0) {
      freq = 90.7;
    } else {
      freq = Math.round(freq * 10) / 10;
    }
    
    onChange(freq);
  }, [onChange]);
  
  const handleMouseDown = (e) => {
    setIsDragging(true);
    handleInteraction(e.clientX);
  };
  
  const handleMouseMove = useCallback((e) => {
    if (isDragging) handleInteraction(e.clientX);
  }, [isDragging, handleInteraction]);
  
  const handleMouseUp = useCallback(() => {
    setIsDragging(false);
  }, []);
  
  useEffect(() => {
    if (isDragging) {
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
      return () => {
        window.removeEventListener('mousemove', handleMouseMove);
        window.removeEventListener('mouseup', handleMouseUp);
      };
    }
  }, [isDragging, handleMouseMove, handleMouseUp]);
  
  const isOnFrequency = frequency === 90.7;
  
  // Markers at even numbers
  const markers = [88, 92, 96, 100, 104, 108];
  
  return (
    <div className="w-full max-w-md mx-auto">
      {/* Frequency display */}
      <div className="text-center mb-4">
        <span 
          className="font-mono text-5xl font-bold tracking-tight"
          style={{ color: isOnFrequency ? '#c41e3a' : '#1a1a1a' }}
        >
          {frequency.toFixed(1)}
        </span>
        <span className="font-mono text-lg ml-2" style={{ color: '#555' }}>FM</span>
      </div>
      
      {/* Dial track container */}
      <div 
        ref={dialRef}
        className="relative h-20 cursor-crosshair select-none bg-white"
        style={{ border: '3px solid #1a1a1a' }}
        onMouseDown={handleMouseDown}
        onTouchStart={(e) => {
          setIsDragging(true);
          handleInteraction(e.touches[0].clientX);
        }}
        onTouchMove={(e) => handleInteraction(e.touches[0].clientX)}
        onTouchEnd={() => setIsDragging(false)}
      >
        {/* Inner track area with padding */}
        <div 
          className="absolute top-0 bottom-0"
          style={{ left: '24px', right: '24px' }}
        >
          {/* Track line */}
          <div 
            className="absolute top-1/2 left-0 right-0 -translate-y-1/2"
            style={{ height: '2px', backgroundColor: '#999' }}
          />
          
          {/* Regular frequency markers */}
          {markers.map((m) => (
            <div
              key={m}
              className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 flex flex-col items-center"
              style={{ left: `${freqToPercent(m)}%` }}
            >
              <div style={{ width: '1px', height: '12px', backgroundColor: '#1a1a1a' }} />
              <span 
                className="font-mono mt-1 font-bold"
                style={{ color: '#555', fontSize: '9px' }}
              >
                {m}
              </span>
            </div>
          ))}
          
          {/* KPFK 90.7 marker - the home frequency */}
          <div
            className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 flex flex-col items-center"
            style={{ left: `${freqToPercent(90.7)}%` }}
          >
            <div style={{ width: '3px', height: '24px', backgroundColor: '#c41e3a' }} />
            <span 
              className="font-mono mt-1 font-bold"
              style={{ color: '#c41e3a', fontSize: '11px' }}
            >
              90.7
            </span>
          </div>
          
          {/* KPFK label badge */}
          <div 
            className="absolute -translate-x-1/2"
            style={{ left: `${freqToPercent(90.7)}%`, top: '4px' }}
          >
            <span 
              className="font-mono font-bold px-2 py-0.5"
              style={{ 
                backgroundColor: '#c41e3a', 
                color: 'white',
                fontSize: '9px',
                letterSpacing: '0.5px'
              }}
            >
              KPFK
            </span>
          </div>
          
          {/* Current position indicator */}
          <div
            className="absolute top-1/2 -translate-y-1/2 -translate-x-1/2 transition-all duration-75"
            style={{ left: `${freqToPercent(frequency)}%` }}
          >
            <div 
              className="flex flex-col items-center"
              style={{ marginTop: '-8px' }}
            >
              <div 
                style={{
                  width: 0,
                  height: 0,
                  borderLeft: '8px solid transparent',
                  borderRight: '8px solid transparent',
                  borderTop: `12px solid ${isOnFrequency ? '#c41e3a' : '#1a1a1a'}`,
                }}
              />
              <div 
                style={{
                  width: '3px',
                  height: '32px',
                  backgroundColor: isOnFrequency ? '#c41e3a' : '#1a1a1a',
                }}
              />
            </div>
          </div>
        </div>
      </div>
      
      {/* Instructions */}
      <p 
        className="text-center mt-3 font-mono text-xs uppercase"
        style={{ color: '#999', letterSpacing: '0.5px' }}
      >
        Drag to tune • Find 90.7
      </p>
    </div>
  );
};

// Subdomain configurations
const SUBDOMAIN_CONFIG = {
  donate: {
    title: 'Donate',
    tagline: '90.7 FM Los Angeles',
    primaryAction: { label: '← Back to Donate', href: '/donate' },
    secondaryAction: { label: 'Listen', href: 'https://kpfk.org/listen' },
    navLinks: [
      { label: 'Give Now', href: '/donate', icon: '♥' },
      { label: 'Monthly', href: '/donate/sustainer', icon: '◉' },
      { label: 'Homepage', href: 'https://kpfk.org', icon: '⌂' },
    ],
    foundMessage: "You found us. Ready to support community radio?",
    lostMessage: "You've drifted off the dial. Tune back to 90.7 to find your way home.",
  },
  admin: {
    title: 'Admin',
    tagline: 'Station Management',
    primaryAction: { label: '← Dashboard', href: '/dashboard' },
    secondaryAction: { label: 'Logout', href: '/logout' },
    navLinks: [
      { label: 'Dashboard', href: '/dashboard', icon: '▦' },
      { label: 'Donors', href: '/donors', icon: '◎' },
      { label: 'Reports', href: '/reports', icon: '▤' },
      { label: 'Settings', href: '/settings', icon: '⚙' },
    ],
    foundMessage: "You found us. Back to the control room?",
    lostMessage: "This page doesn't exist. Let's get you back to the dashboard.",
  },
  my: {
    title: 'My KPFK',
    tagline: 'Donor Portal',
    primaryAction: { label: '← My Account', href: '/account' },
    secondaryAction: { label: 'Donate', href: 'https://donate.kpfk.org' },
    navLinks: [
      { label: 'Account', href: '/account', icon: '◉' },
      { label: 'History', href: '/history', icon: '▤' },
      { label: 'Settings', href: '/settings', icon: '⚙' },
      { label: 'Homepage', href: 'https://kpfk.org', icon: '⌂' },
    ],
    foundMessage: "You found us. Let's get you back to your account.",
    lostMessage: "You've drifted off the dial. Tune back to 90.7 to find your way home.",
  },
  catchall: {
    title: 'KPFK',
    tagline: '90.7 FM Los Angeles',
    primaryAction: { label: 'Main Site', href: 'https://kpfk.org' },
    secondaryAction: { label: 'Support', href: 'https://donate.kpfk.org' },
    navLinks: [
      { label: 'Listen Live', href: 'https://kpfk.org/listen', icon: '▶' },
      { label: 'Donate', href: 'https://donate.kpfk.org', icon: '♥' },
      { label: 'My Account', href: 'https://my.kpfk.org', icon: '◉' },
      { label: 'Staff Login', href: 'https://admin.kpfk.org', icon: '⚙' },
    ],
    foundMessage: "You found us — but this page doesn't exist. Here's where you might be headed.",
    lostMessage: "This page doesn't exist. Tune to 90.7 and we'll help you find your way.",
  },
  default: {
    title: 'KPFK',
    tagline: '90.7 FM Los Angeles',
    primaryAction: { label: '▶ Listen', href: 'https://kpfk.org/listen' },
    secondaryAction: { label: 'Support', href: 'https://donate.kpfk.org' },
    navLinks: [
      { label: 'Homepage', href: 'https://kpfk.org', icon: '⌂' },
      { label: 'Schedule', href: 'https://kpfk.org/schedule', icon: '▦' },
      { label: 'Shows', href: 'https://kpfk.org/shows', icon: '◉' },
      { label: 'Archives', href: 'https://kpfk.org/archives', icon: '▤' },
    ],
    foundMessage: "You found us. Welcome back to the frequency.",
    lostMessage: "You've drifted off the dial. Tune back to 90.7 to find your way home.",
  },
};

// Auto-detect subdomain from hostname
const getSubdomain = () => {
  if (typeof window === 'undefined') return 'default';
  const host = window.location.hostname;
  const parts = host.split('.');
  // e.g., donate.kpfk.org -> ['donate', 'kpfk', 'org']
  if (parts.length >= 3 && parts[0] !== 'www') {
    return parts[0];
  }
  return 'default';
};

// Main 404 component
// Usage: <NotFound /> (auto-detects) or <NotFound subdomain="donate" /> (explicit)
export default function NotFound({ subdomain }) {
  const detected = subdomain || getSubdomain();
  const config = SUBDOMAIN_CONFIG[detected] || SUBDOMAIN_CONFIG.catchall;
  const [frequency, setFrequency] = useState(98.7);
  const [isSearching, setIsSearching] = useState(false);
  const [showFound, setShowFound] = useState(false);
  
  const signalStrength = 1 - Math.min(1, Math.abs(frequency - 90.7) / 5);
  const isOnFrequency = Math.abs(frequency - 90.7) < 0.3;
  
  useEffect(() => {
    if (isOnFrequency && !showFound) {
      const timer = setTimeout(() => setShowFound(true), 400);
      return () => clearTimeout(timer);
    } else if (!isOnFrequency) {
      setShowFound(false);
    }
  }, [isOnFrequency, showFound]);
  
  const handleAutoTune = () => {
    setIsSearching(true);
    let current = frequency;
    const target = 90.7;
    const step = (target - current) / 25;
    
    const interval = setInterval(() => {
      current += step + (Math.random() - 0.5) * 0.3;
      if (Math.abs(current - target) < 0.15) {
        setFrequency(90.7);
        setIsSearching(false);
        clearInterval(interval);
      } else {
        setFrequency(Math.round(current * 10) / 10);
      }
    }, 60);
  };
  
  return (
    <div 
      className="min-h-screen flex flex-col relative"
      style={{ backgroundColor: '#fff', color: '#1a1a1a' }}
    >
      <NewsprintTexture opacity={0.03} />
      
      {/* Header */}
      <header 
        className="relative z-10 px-6 py-4 flex items-center justify-between"
        style={{ borderBottom: '4px solid #c41e3a' }}
      >
        <a href="#" className="flex items-center gap-3 hover:opacity-80 transition-opacity">
          <div className="flex flex-col">
            <span 
              className="text-xl font-black uppercase tracking-tight"
              style={{ fontFamily: 'Helvetica Neue, Helvetica, Arial, sans-serif' }}
            >
              {config.title}
            </span>
            <span 
              className="font-mono text-xs font-bold uppercase"
              style={{ color: '#555', letterSpacing: '0.5px' }}
            >
              {config.tagline}
            </span>
          </div>
        </a>
        
        <nav className="flex items-center gap-4">
          <a 
            href={config.primaryAction.href}
            className="px-4 py-2 font-bold text-sm uppercase transition-colors hover:bg-black hover:text-white"
            style={{ 
              fontFamily: 'Helvetica Neue, Helvetica, Arial, sans-serif',
              border: '3px solid #1a1a1a',
              letterSpacing: '0.5px'
            }}
          >
            {config.primaryAction.label}
          </a>
          <a 
            href={config.secondaryAction.href}
            className="px-4 py-2 font-bold text-sm uppercase transition-opacity hover:opacity-80"
            style={{ 
              fontFamily: 'Helvetica Neue, Helvetica, Arial, sans-serif',
              backgroundColor: '#c41e3a',
              color: 'white',
              border: '3px solid #c41e3a',
              letterSpacing: '0.5px'
            }}
          >
            {config.secondaryAction.label}
          </a>
        </nav>
      </header>
      
      {/* Main content */}
      <main className="relative z-10 flex-1 flex flex-col items-center justify-center px-6 py-12">
        <div className="w-full max-w-xl mx-auto">
          
          {/* Status badge */}
          <div className="text-center mb-6">
            <span 
              className="inline-block px-3 py-1 font-mono text-xs font-bold uppercase"
              style={{ 
                border: `2px solid ${isOnFrequency ? '#c41e3a' : '#1a1a1a'}`,
                color: isOnFrequency ? '#c41e3a' : '#1a1a1a',
                letterSpacing: '0.5px'
              }}
            >
              {isSearching ? '◎ Scanning...' : isOnFrequency ? '◉ Signal Found' : '○ Signal Lost'}
            </span>
          </div>
          
          {/* 404 */}
          <h1 
            className="text-center font-black uppercase tracking-tighter mb-2"
            style={{ 
              fontFamily: 'Helvetica Neue, Helvetica, Arial, sans-serif',
              fontSize: 'clamp(72px, 15vw, 120px)',
              lineHeight: 1,
              color: '#1a1a1a'
            }}
          >
            <span style={{ color: isOnFrequency ? '#c41e3a' : '#1a1a1a' }}>4</span>
            <span style={{ color: '#999' }}>0</span>
            <span style={{ color: isOnFrequency ? '#c41e3a' : '#1a1a1a' }}>4</span>
          </h1>
          
          {/* Message */}
          <p 
            className="text-center mb-8"
            style={{ 
              fontFamily: 'Georgia, Times New Roman, serif',
              fontSize: '18px',
              lineHeight: 1.6,
              color: '#555',
              maxWidth: '400px',
              margin: '0 auto 32px'
            }}
          >
            {showFound ? config.foundMessage : config.lostMessage}
          </p>
          
          {/* Waveform */}
          <div className="mb-8">
            <Waveform signalStrength={signalStrength} isSearching={isSearching} />
          </div>
          
          {/* Frequency dial */}
          <div className="mb-8">
            <FrequencyDial 
              frequency={frequency} 
              onChange={setFrequency}
              isSearching={isSearching}
            />
          </div>
          
          {/* Auto-tune button */}
          {!isOnFrequency && (
            <div className="text-center mb-8">
              <button
                onClick={handleAutoTune}
                disabled={isSearching}
                className="font-mono text-xs uppercase underline underline-offset-4 hover:no-underline disabled:opacity-50"
                style={{ color: '#555', letterSpacing: '0.5px' }}
              >
                {isSearching ? 'Scanning frequencies...' : '→ Auto-tune to 90.7'}
              </button>
            </div>
          )}
          
          {/* Live Player - appears when signal found */}
          <div className="mb-8">
            <LivePlayer isVisible={showFound} />
          </div>
          
          {/* Navigation links */}
          <nav 
            className="flex flex-wrap justify-center gap-x-6 gap-y-2"
            style={{ 
              opacity: showFound ? 1 : 0.5,
              transition: 'opacity 0.5s'
            }}
          >
            {config.navLinks.map(({ label, href, icon }) => (
              <a
                key={label}
                href={href}
                className="font-mono text-xs uppercase hover:underline underline-offset-4"
                style={{ color: '#555', letterSpacing: '0.5px' }}
              >
                {icon} {label}
              </a>
            ))}
          </nav>
          
        </div>
      </main>
      
      {/* Footer */}
      <footer 
        className="relative z-10 px-6 py-4 text-center"
        style={{ borderTop: '3px solid #1a1a1a' }}
      >
        <p 
          className="font-mono text-xs uppercase"
          style={{ color: '#999', letterSpacing: '0.5px' }}
        >
          KPFK 90.7 FM • Pacifica Radio • Listener-Supported Since 1959
        </p>
      </footer>
    </div>
  );
}
