import React, {type ReactNode, useState, useEffect} from 'react';
import Mermaid from '@theme-original/Mermaid';
import type MermaidType from '@theme/Mermaid';
import type {WrapperProps} from '@docusaurus/types';
import { TransformWrapper, TransformComponent, useControls } from 'react-zoom-pan-pinch';
import { ZoomIn, ZoomOut, Maximize2, Minimize2, RotateCcw } from 'lucide-react';
import clsx from 'clsx';
import { createPortal } from 'react-dom';

type Props = WrapperProps<typeof MermaidType>;

const Controls = ({ onToggleFullscreen, isFullscreen }: { onToggleFullscreen: () => void, isFullscreen: boolean }) => {
  const { zoomIn, zoomOut, resetTransform } = useControls();

  return (
    <div className="mermaid-zoom-controls">
      <button className="mermaid-zoom-button" onClick={() => zoomIn()} title="Zoom In">
        <ZoomIn size={18} />
      </button>
      <button className="mermaid-zoom-button" onClick={() => zoomOut()} title="Zoom Out">
        <ZoomOut size={18} />
      </button>
      <button className="mermaid-zoom-button" onClick={() => resetTransform()} title="Reset">
        <RotateCcw size={18} />
      </button>
      <button className="mermaid-zoom-button" onClick={onToggleFullscreen} title={isFullscreen ? "Exit Fullscreen" : "Fullscreen"}>
        {isFullscreen ? <Minimize2 size={18} /> : <Maximize2 size={18} />}
      </button>
    </div>
  );
};

export default function MermaidWrapper(props: Props): ReactNode {
  const [isFullscreen, setIsFullscreen] = useState(false);
  const [isMounted, setIsMounted] = useState(false);

  useEffect(() => {
    setIsMounted(true);
    if (isFullscreen) {
      document.body.style.overflow = 'hidden';
    } else {
      document.body.style.overflow = 'unset';
    }
    return () => {
      document.body.style.overflow = 'unset';
    };
  }, [isFullscreen]);

  const toggleFullscreen = () => setIsFullscreen(!isFullscreen);

  const content = (
    <div className={clsx("mermaid-zoom-container", isFullscreen && "mermaid-fullscreen-overlay")}>
      {isFullscreen && (
        <div className="mermaid-fullscreen-header">
           <button className="mermaid-zoom-button" onClick={toggleFullscreen}>
             <Minimize2 size={18} />
           </button>
        </div>
      )}
      <TransformWrapper
        initialScale={1}
        minScale={0.5}
        maxScale={4}
        centerOnInit={true}
        wheel={{ step: 0.1 }}
      >
        <Controls onToggleFullscreen={toggleFullscreen} isFullscreen={isFullscreen} />
        <TransformComponent
          wrapperStyle={{
            width: '100%',
            height: isFullscreen ? 'calc(100vh - 60px)' : '400px',
            cursor: 'grab'
          }}
          contentStyle={{
             width: '100%',
             height: '100%',
             display: 'flex',
             alignItems: 'center',
             justifyContent: 'center'
          }}
        >
          <div style={{ padding: '20px', minWidth: '100%' }}>
            <Mermaid {...props} />
          </div>
        </TransformComponent>
      </TransformWrapper>
    </div>
  );

  if (isFullscreen && isMounted) {
    return createPortal(content, document.body);
  }

  return content;
}

