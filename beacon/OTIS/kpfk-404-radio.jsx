import React, { useState, useEffect, useRef, useCallback } from 'react';

// Skeuomorphic car radio 404 page
// Vintage 70s/80s car stereo aesthetic

// Volume knob component
const VolumeKnob = ({ volume, onChange }) => {
  const knobRef = useRef(null);
  const [isDragging, setIsDragging] = useState(false);
  const [startY, setStartY] = useState(0);
  const [startVolume, setStartVolume] = useState(volume);
  
  const rotation = -135 + (volume * 270); // -135 to +135 degrees
  
  const handleMouseDown = (e) => {
    setIsDragging(true);
    setStartY(e.clientY);
    setStartVolume(volume);
    e.preventDefault();
  };
  
  const handleMouseMove = useCallback((e) => {
    if (!isDragging) return;
    const deltaY = startY - e.clientY;
    const deltaVolume = deltaY / 100;
    const newVolume = Math.max(0, Math.min(1, startVolume + deltaVolume));
    onChange(newVolume);
  }, [isDragging, startY, startVolume, onChange]);
  
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
  
  return (
    <div className="flex flex-col items-center gap-1">
      {/* Outer container with stationary reference marks */}
      <div className="relative" style={{ width: '72px', height: '72px' }}>
        {/* Stationary tick marks around the outside */}
        {[...Array(11)].map((_, i) => {
          const angle = -135 + (i * 27); // Spread from -135 to +135
          return (
            <div
              key={i}
              className="absolute"
              style={{
                width: '2px',
                height: '6px',
                backgroundColor: '#4a4a4a',
                left: '50%',
                top: '50%',
                transformOrigin: 'center center',
                transform: `translate(-50%, -50%) rotate(${angle}deg) translateY(-32px)`,
              }}
            />
          );
        })}
        
        {/* The knob itself */}
        <div
          ref={knobRef}
          onMouseDown={handleMouseDown}
          onTouchStart={(e) => {
            setIsDragging(true);
            setStartY(e.touches[0].clientY);
            setStartVolume(volume);
          }}
          onTouchMove={(e) => {
            if (!isDragging) return;
            const deltaY = startY - e.touches[0].clientY;
            const deltaVolume = deltaY / 100;
            const newVolume = Math.max(0, Math.min(1, startVolume + deltaVolume));
            onChange(newVolume);
          }}
          onTouchEnd={() => setIsDragging(false)}
          className="absolute cursor-grab active:cursor-grabbing select-none"
          style={{
            width: '56px',
            height: '56px',
            left: '50%',
            top: '50%',
            transform: 'translate(-50%, -50%)',
            borderRadius: '50%',
            background: 'linear-gradient(145deg, #4a4a4a 0%, #2a2a2a 50%, #1a1a1a 100%)',
            boxShadow: `
              0 2px 4px rgba(0,0,0,0.5),
              inset 0 1px 1px rgba(255,255,255,0.1),
              inset 0 -1px 1px rgba(0,0,0,0.3)
            `,
            border: '2px solid #1a1a1a',
          }}
        >
          {/* Knob indicator line */}
          <div
            className="absolute top-1/2 left-1/2"
            style={{
              width: '2px',
              height: '20px',
              backgroundColor: '#e0e0e0',
              transformOrigin: 'center bottom',
              transform: `translate(-50%, -100%) rotate(${rotation}deg)`,
              boxShadow: '0 0 2px rgba(255,255,255,0.3)',
            }}
          />
          {/* Center cap */}
          <div
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
            style={{
              width: '16px',
              height: '16px',
              borderRadius: '50%',
              background: 'linear-gradient(145deg, #3a3a3a, #1a1a1a)',
              border: '1px solid #0a0a0a',
            }}
          />
        </div>
      </div>
      <span style={{ 
        color: '#888', 
        fontSize: '9px', 
        fontFamily: 'Arial, sans-serif',
        textTransform: 'uppercase',
        letterSpacing: '1px',
      }}>
        Volume
      </span>
    </div>
  );
};

// Tuning knob component
const TuningKnob = ({ frequency, onChange }) => {
  const knobRef = useRef(null);
  const [isDragging, setIsDragging] = useState(false);
  const [startX, setStartX] = useState(0);
  const [startFreq, setStartFreq] = useState(frequency);
  
  // Visual rotation based on frequency - indicator points to position
  const rotation = -135 + ((frequency - 88) / 20) * 270; // -135 to +135 degrees
  
  const handleMouseDown = (e) => {
    setIsDragging(true);
    setStartX(e.clientX);
    setStartFreq(frequency);
    e.preventDefault();
  };
  
  const handleMouseMove = useCallback((e) => {
    if (!isDragging) return;
    const deltaX = e.clientX - startX;
    const deltaFreq = deltaX / 15;
    let newFreq = startFreq + deltaFreq;
    
    // Sticky zone for KPFK
    if (Math.abs(newFreq - 90.7) < 0.8) {
      newFreq = 90.7;
    } else {
      newFreq = Math.max(88, Math.min(108, Math.round(newFreq * 10) / 10));
    }
    
    onChange(newFreq);
  }, [isDragging, startX, startFreq, onChange]);
  
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
  
  return (
    <div className="flex flex-col items-center gap-1">
      {/* Outer container with stationary reference marks */}
      <div className="relative" style={{ width: '72px', height: '72px' }}>
        {/* Stationary tick marks around the outside */}
        {[...Array(11)].map((_, i) => {
          const angle = -135 + (i * 27); // Spread from -135 to +135
          return (
            <div
              key={i}
              className="absolute"
              style={{
                width: '2px',
                height: '6px',
                backgroundColor: '#4a4a4a',
                left: '50%',
                top: '50%',
                transformOrigin: 'center center',
                transform: `translate(-50%, -50%) rotate(${angle}deg) translateY(-32px)`,
              }}
            />
          );
        })}
        
        {/* The knob itself */}
        <div
          ref={knobRef}
          onMouseDown={handleMouseDown}
          onTouchStart={(e) => {
            setIsDragging(true);
            setStartX(e.touches[0].clientX);
            setStartFreq(frequency);
          }}
          onTouchMove={(e) => {
            if (!isDragging) return;
            const deltaX = e.touches[0].clientX - startX;
            const deltaFreq = deltaX / 15;
            let newFreq = startFreq + deltaFreq;
            if (Math.abs(newFreq - 90.7) < 0.8) {
              newFreq = 90.7;
            } else {
              newFreq = Math.max(88, Math.min(108, Math.round(newFreq * 10) / 10));
            }
            onChange(newFreq);
          }}
          onTouchEnd={() => setIsDragging(false)}
          className="absolute cursor-grab active:cursor-grabbing select-none"
          style={{
            width: '56px',
            height: '56px',
            left: '50%',
            top: '50%',
            transform: 'translate(-50%, -50%)',
            borderRadius: '50%',
            background: 'linear-gradient(145deg, #4a4a4a 0%, #2a2a2a 50%, #1a1a1a 100%)',
            boxShadow: `
              0 2px 4px rgba(0,0,0,0.5),
              inset 0 1px 1px rgba(255,255,255,0.1),
              inset 0 -1px 1px rgba(0,0,0,0.3)
            `,
            border: '2px solid #1a1a1a',
          }}
        >
          {/* Indicator line on knob */}
          <div
            className="absolute top-1/2 left-1/2"
            style={{
              width: '2px',
              height: '20px',
              backgroundColor: '#e0e0e0',
              transformOrigin: 'center bottom',
              transform: `translate(-50%, -100%) rotate(${rotation}deg)`,
              boxShadow: '0 0 2px rgba(255,255,255,0.3)',
            }}
          />
          {/* Center cap */}
          <div
            className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2"
            style={{
              width: '16px',
              height: '16px',
              borderRadius: '50%',
              background: 'linear-gradient(145deg, #3a3a3a, #1a1a1a)',
              border: '1px solid #0a0a0a',
            }}
          />
        </div>
      </div>
      <span style={{ 
        color: '#888', 
        fontSize: '9px', 
        fontFamily: 'Arial, sans-serif',
        textTransform: 'uppercase',
        letterSpacing: '1px',
      }}>
        Tune
      </span>
    </div>
  );
};

// LED indicator
const LED = ({ on, color = 'green' }) => {
  const colors = {
    green: { on: '#00ff00', glow: 'rgba(0,255,0,0.6)' },
    red: { on: '#ff3333', glow: 'rgba(255,50,50,0.6)' },
    amber: { on: '#ffaa00', glow: 'rgba(255,170,0,0.6)' },
  };
  
  return (
    <div
      style={{
        width: '8px',
        height: '8px',
        borderRadius: '50%',
        backgroundColor: on ? colors[color].on : '#333',
        boxShadow: on ? `0 0 6px ${colors[color].glow}, 0 0 12px ${colors[color].glow}` : 'inset 0 1px 2px rgba(0,0,0,0.5)',
        border: '1px solid #1a1a1a',
      }}
    />
  );
};

// Preset button
const PresetButton = ({ label, number, active, onClick }) => (
  <button
    onClick={onClick}
    className="flex flex-col items-center justify-center transition-all active:scale-95"
    style={{
      width: '48px',
      height: '36px',
      background: active 
        ? 'linear-gradient(180deg, #4a4a4a 0%, #2a2a2a 100%)'
        : 'linear-gradient(180deg, #3a3a3a 0%, #1a1a1a 100%)',
      border: '1px solid #0a0a0a',
      borderRadius: '3px',
      boxShadow: active
        ? 'inset 0 2px 4px rgba(0,0,0,0.5), 0 0 8px rgba(255,170,0,0.3)'
        : '0 2px 4px rgba(0,0,0,0.3), inset 0 1px 0 rgba(255,255,255,0.05)',
      cursor: 'pointer',
    }}
  >
    <span style={{ 
      color: active ? '#ffaa00' : '#ff8c42', 
      fontSize: '8px', 
      fontFamily: 'Arial, sans-serif',
      textTransform: 'uppercase',
      letterSpacing: '0.5px',
      textShadow: active 
        ? '0 0 6px rgba(255,170,0,0.8)' 
        : '0 0 4px rgba(255,140,66,0.3)',
      opacity: active ? 1 : 0.7,
    }}>
      {label}
    </span>
    <span style={{ 
      color: active ? '#ffaa00' : '#ff8c42', 
      fontSize: '11px', 
      fontFamily: 'monospace',
      fontWeight: 'bold',
      textShadow: active 
        ? '0 0 8px rgba(255,170,0,0.8)' 
        : '0 0 4px rgba(255,140,66,0.3)',
      opacity: active ? 1 : 0.7,
    }}>
      {number}
    </span>
  </button>
);

// Main component
export default function NotFound({ subdomain }) {
  const audioRef = useRef(null);
  const [frequency, setFrequency] = useState(94.5);
  const [volume, setVolume] = useState(0.7);
  const [isPlaying, setIsPlaying] = useState(false);
  const [isPoweredOn, setIsPoweredOn] = useState(true);
  
  const isOnFrequency = frequency === 90.7;
  
  // Handle volume changes
  useEffect(() => {
    if (audioRef.current) {
      audioRef.current.volume = volume;
    }
  }, [volume]);
  
  // Stop audio when tuned away
  useEffect(() => {
    if (!isOnFrequency && isPlaying && audioRef.current) {
      audioRef.current.pause();
      setIsPlaying(false);
    }
  }, [isOnFrequency, isPlaying]);
  
  const togglePlay = () => {
    if (!audioRef.current || !isOnFrequency) return;
    
    if (isPlaying) {
      audioRef.current.pause();
      setIsPlaying(false);
    } else {
      audioRef.current.play().then(() => {
        setIsPlaying(true);
      }).catch(console.error);
    }
  };
  
  const handlePreset = (freq) => {
    setFrequency(freq);
  };
  
  // Calculate dial position
  const dialPosition = ((frequency - 88) / 20) * 100;
  
  return (
    <div 
      className="min-h-screen flex flex-col items-center justify-center p-4"
      style={{
        background: 'linear-gradient(180deg, #1a1a1a 0%, #0a0a0a 50%, #1a1a1a 100%)',
      }}
    >
      <audio
        ref={audioRef}
        src="https://streams.pacifica.org:9000/kpfk_128"
        preload="none"
      />
      
      {/* Big clear 404 */}
      <h1 style={{
        fontFamily: 'Arial Black, sans-serif',
        fontSize: '72px',
        fontWeight: '900',
        color: '#333',
        letterSpacing: '-2px',
        marginBottom: '8px',
        textShadow: '0 2px 0 #111',
      }}>
        404
      </h1>
      
      {/* Message above radio */}
      <div className="text-center mb-6">
        <p style={{
          fontFamily: 'Georgia, serif',
          fontSize: '16px',
          color: '#555',
        }}>
          {isOnFrequency 
            ? "You found the signal." 
            : "Page not found. Tune to 90.7."}
        </p>
      </div>
      
      {/* Car Radio Unit */}
      <div
        style={{
          width: '100%',
          maxWidth: '480px',
          background: 'linear-gradient(180deg, #2a2a2a 0%, #1a1a1a 5%, #1a1a1a 95%, #0a0a0a 100%)',
          borderRadius: '8px',
          padding: '4px',
          boxShadow: `
            0 8px 32px rgba(0,0,0,0.5),
            0 2px 4px rgba(0,0,0,0.3),
            inset 0 1px 0 rgba(255,255,255,0.05)
          `,
          border: '1px solid #333',
        }}
      >
        {/* Chrome bezel */}
        <div
          style={{
            position: 'relative',
            background: 'linear-gradient(180deg, #4a4a4a 0%, #2a2a2a 50%, #3a3a3a 100%)',
            borderRadius: '6px',
            padding: '12px',
            border: '1px solid #1a1a1a',
          }}
        >
          {/* Embossed model number */}
          <div
            style={{
              position: 'absolute',
              top: '6px',
              right: '12px',
              fontFamily: 'Arial Black, Impact, sans-serif',
              fontSize: '10px',
              fontWeight: '900',
              letterSpacing: '1px',
              color: 'transparent',
              textShadow: `
                0 1px 0 rgba(255,255,255,0.1),
                0 -1px 0 rgba(0,0,0,0.4)
              `,
              WebkitBackgroundClip: 'text',
              backgroundClip: 'text',
              backgroundColor: '#3a3a3a',
            }}
          >
            MODEL 404
          </div>
          
          {/* Stamped effect overlay */}
          <div
            style={{
              position: 'absolute',
              top: '6px',
              right: '12px',
              fontFamily: 'Arial Black, Impact, sans-serif',
              fontSize: '10px',
              fontWeight: '900',
              letterSpacing: '1px',
              color: '#2a2a2a',
              textShadow: `
                1px 1px 0 rgba(255,255,255,0.08),
                -1px -1px 0 rgba(0,0,0,0.3)
              `,
            }}
          >
            MODEL 404
          </div>
          {/* Main faceplate */}
          <div
            style={{
              background: 'linear-gradient(180deg, #1f1f1f 0%, #171717 100%)',
              borderRadius: '4px',
              padding: '16px',
              boxShadow: 'inset 0 2px 8px rgba(0,0,0,0.5)',
            }}
          >
            
            {/* Top row: Display */}
            <div
              style={{
                background: '#0a0a0a',
                borderRadius: '2px',
                padding: '12px 16px',
                marginBottom: '16px',
                boxShadow: 'inset 0 2px 8px rgba(0,0,0,0.8)',
                border: '1px solid #000',
              }}
            >
              {/* LCD Display area */}
              <div className="flex items-center justify-between mb-3">
                <div className="flex items-center gap-2">
                  <LED on={isPoweredOn} color="green" />
                  <span style={{ 
                    color: '#ffaa00', 
                    fontSize: '10px', 
                    fontFamily: 'Arial, sans-serif',
                    textTransform: 'uppercase',
                    letterSpacing: '1px',
                    textShadow: '0 0 4px rgba(255,170,0,0.5)',
                  }}>
                    FM
                  </span>
                </div>
                
                {/* Frequency display */}
                <div style={{
                  fontFamily: '"Courier New", monospace',
                  fontSize: '32px',
                  fontWeight: 'bold',
                  color: isOnFrequency ? '#ff6b35' : '#ff8c42',
                  textShadow: isOnFrequency 
                    ? '0 0 10px rgba(255,107,53,0.8), 0 0 20px rgba(255,107,53,0.4)'
                    : '0 0 8px rgba(255,140,66,0.5)',
                  letterSpacing: '-1px',
                }}>
                  {frequency.toFixed(1)}
                </div>
                
                <div className="flex items-center gap-2">
                  <LED on={isOnFrequency} color="amber" />
                  <span style={{ 
                    color: isOnFrequency ? '#ffaa00' : '#444', 
                    fontSize: '10px', 
                    fontFamily: 'Arial, sans-serif',
                    textTransform: 'uppercase',
                    letterSpacing: '1px',
                    textShadow: isOnFrequency ? '0 0 4px rgba(255,170,0,0.5)' : 'none',
                  }}>
                    {isOnFrequency ? 'KPFK' : 'SCAN'}
                  </span>
                </div>
              </div>
              
              {/* Frequency dial/scale */}
              <div 
                style={{
                  position: 'relative',
                  height: '24px',
                  background: 'linear-gradient(180deg, #0f0f0f 0%, #1a1a1a 100%)',
                  borderRadius: '2px',
                  overflow: 'hidden',
                  border: '1px solid #000',
                }}
              >
                {/* Inner track with padding */}
                <div 
                  className="absolute"
                  style={{ left: '8px', right: '8px', top: 0, bottom: 0 }}
                >
                  {/* Dial markings */}
                  <div className="absolute inset-0 flex items-center justify-between">
                    {[88, 92, 96, 100, 104, 108].map((f) => (
                      <div key={f} className="flex flex-col items-center">
                        <div style={{ 
                          width: '1px', 
                          height: '6px', 
                          backgroundColor: '#444',
                        }} />
                        <span style={{ 
                          color: '#555', 
                          fontSize: '8px', 
                          fontFamily: 'Arial, sans-serif',
                          marginTop: '1px',
                        }}>
                          {f}
                        </span>
                      </div>
                    ))}
                  </div>
                  
                  {/* KPFK marker */}
                  <div
                    className="absolute top-0"
                    style={{
                      left: `${((90.7 - 88) / 20) * 100}%`,
                      transform: 'translateX(-50%)',
                    }}
                  >
                    <div style={{
                      width: '2px',
                      height: '8px',
                      backgroundColor: '#c41e3a',
                      boxShadow: '0 0 4px rgba(196,30,58,0.8)',
                    }} />
                  </div>
                  
                  {/* Tuning indicator (red line) */}
                  <div
                    className="absolute top-0 bottom-0 transition-all duration-100"
                    style={{
                      left: `${dialPosition}%`,
                      transform: 'translateX(-50%)',
                      width: '2px',
                      backgroundColor: '#ff3333',
                      boxShadow: '0 0 8px rgba(255,51,51,0.8), 0 0 16px rgba(255,51,51,0.4)',
                    }}
                  />
                </div>
              </div>
            </div>
            
            {/* Middle row: Controls */}
            <div className="flex items-center justify-between mb-4">
              <VolumeKnob volume={volume} onChange={setVolume} />
              
              {/* Play button - only works when on frequency */}
              <button
                onClick={togglePlay}
                disabled={!isOnFrequency}
                className="transition-all active:scale-95"
                style={{
                  width: '64px',
                  height: '64px',
                  borderRadius: '50%',
                  background: isOnFrequency
                    ? 'linear-gradient(180deg, #c41e3a 0%, #8b1528 100%)'
                    : 'linear-gradient(180deg, #3a3a3a 0%, #1a1a1a 100%)',
                  border: '2px solid #0a0a0a',
                  boxShadow: isOnFrequency
                    ? '0 4px 12px rgba(196,30,58,0.4), inset 0 1px 0 rgba(255,255,255,0.2)'
                    : '0 2px 4px rgba(0,0,0,0.3)',
                  cursor: isOnFrequency ? 'pointer' : 'not-allowed',
                  display: 'flex',
                  alignItems: 'center',
                  justifyContent: 'center',
                  opacity: isOnFrequency ? 1 : 0.5,
                }}
              >
                {isPlaying ? (
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="white">
                    <rect x="4" y="4" width="16" height="16" rx="2" />
                  </svg>
                ) : (
                  <svg width="24" height="24" viewBox="0 0 24 24" fill="white" style={{ marginLeft: '3px' }}>
                    <polygon points="5,3 19,12 5,21" />
                  </svg>
                )}
              </button>
              
              <TuningKnob frequency={frequency} onChange={setFrequency} />
            </div>
            
            {/* Bottom row: Presets */}
            <div className="flex items-center justify-between gap-2">
              <PresetButton label="Home" number="1" active={false} onClick={() => window.location.href = 'https://kpfk.org'} />
              <PresetButton label="KPFK" number="90.7" active={isOnFrequency} onClick={() => handlePreset(90.7)} />
              <PresetButton label="Give" number="3" active={false} onClick={() => window.location.href = 'https://donate.kpfk.org'} />
              <PresetButton label="Shows" number="4" active={false} onClick={() => window.location.href = 'https://kpfk.org/shows'} />
              <PresetButton label="Sched" number="5" active={false} onClick={() => window.location.href = 'https://kpfk.org/schedule'} />
            </div>
            
          </div>
        </div>
        
        {/* Brand plate */}
        <div className="flex items-center justify-center mt-2 mb-1">
          <span style={{
            fontFamily: 'Arial Black, sans-serif',
            fontSize: '11px',
            color: '#555',
            letterSpacing: '3px',
            textTransform: 'uppercase',
          }}>
            KPFK • Los Angeles
          </span>
        </div>
      </div>
      
      {/* Instructions */}
      <p style={{
        color: '#444',
        fontSize: '12px',
        fontFamily: 'Georgia, serif',
        marginTop: '24px',
        textAlign: 'center',
      }}>
        Drag the TUNE knob to find 90.7 FM • Press play to listen
      </p>
      
      {/* Footer links */}
      <div className="flex items-center gap-6 mt-8">
        {[
          { label: 'Homepage', href: 'https://kpfk.org' },
          { label: 'Schedule', href: 'https://kpfk.org/schedule' },
          { label: 'Donate', href: 'https://donate.kpfk.org' },
        ].map(({ label, href }) => (
          <a
            key={label}
            href={href}
            style={{
              color: '#555',
              fontSize: '12px',
              fontFamily: 'Arial, sans-serif',
              textDecoration: 'none',
              borderBottom: '1px solid transparent',
            }}
            onMouseOver={(e) => e.target.style.borderBottomColor = '#555'}
            onMouseOut={(e) => e.target.style.borderBottomColor = 'transparent'}
          >
            {label}
          </a>
        ))}
      </div>
      
      <p style={{
        color: '#333',
        fontSize: '10px',
        fontFamily: 'Arial, sans-serif',
        marginTop: '32px',
        textTransform: 'uppercase',
        letterSpacing: '1px',
      }}>
        KPFK 90.7 FM • Pacifica Radio • Since 1959
      </p>
    </div>
  );
}
