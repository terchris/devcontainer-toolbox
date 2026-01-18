import type {ReactNode} from 'react';
import useBaseUrl from '@docusaurus/useBaseUrl';
import styles from './styles.module.css';
import {defaultCubes, type CubeConfig} from './cubeConfig';

type IsometricCubeProps = {
  logos: { top: string; front: string; back: string; left: string; right: string };
  names: { top: string; front: string; back: string; left: string; right: string };
  size: 'small' | 'medium' | 'large';
  style?: React.CSSProperties;
  delay: number;
};

function IsometricCube({ logos, names, size, style, delay }: IsometricCubeProps): ReactNode {
  const topLogoPath = useBaseUrl(`/img/tools/${logos.top}`);
  const frontLogoPath = useBaseUrl(`/img/tools/${logos.front}`);
  const backLogoPath = useBaseUrl(`/img/tools/${logos.back}`);
  const leftLogoPath = useBaseUrl(`/img/tools/${logos.left}`);
  const rightLogoPath = useBaseUrl(`/img/tools/${logos.right}`);

  const sizeClass = {
    small: styles.cubeSmall,
    medium: styles.cubeMedium,
    large: styles.cubeLarge,
  }[size];

  return (
    <div
      className={`${styles.cubeWrapper} ${sizeClass}`}
      style={{ ...style, animationDelay: `${delay}s` }}
    >
      <div className={styles.cube} style={{ animationDelay: `${delay}s` }}>
        {/* Top face */}
        <div className={`${styles.face} ${styles.faceTop}`}>
          <img src={topLogoPath} alt={names.top} className={styles.faceLogo} loading="lazy" />
        </div>
        {/* Front face */}
        <div className={`${styles.face} ${styles.faceFront}`}>
          <img src={frontLogoPath} alt={names.front} className={styles.faceLogo} loading="lazy" />
        </div>
        {/* Back face */}
        <div className={`${styles.face} ${styles.faceBack}`}>
          <img src={backLogoPath} alt={names.back} className={styles.faceLogo} loading="lazy" />
        </div>
        {/* Left face */}
        <div className={`${styles.face} ${styles.faceLeft}`}>
          <img src={leftLogoPath} alt={names.left} className={styles.faceLogo} loading="lazy" />
        </div>
        {/* Right face */}
        <div className={`${styles.face} ${styles.faceRight}`}>
          <img src={rightLogoPath} alt={names.right} className={styles.faceLogo} loading="lazy" />
        </div>
      </div>
    </div>
  );
}

type FloatingCubesProps = {
  cubes?: CubeConfig[];
  className?: string;
};

export default function FloatingCubes({ cubes = defaultCubes, className }: FloatingCubesProps): ReactNode {
  return (
    <div className={`${styles.scene} ${className || ''}`}>
      {cubes.map((cube, index) => (
        <IsometricCube
          key={index}
          logos={cube.logos}
          names={cube.names}
          size={cube.size}
          delay={cube.delay}
          style={{
            left: `${cube.position.x}%`,
            top: `${cube.position.y}%`,
          }}
        />
      ))}
    </div>
  );
}
