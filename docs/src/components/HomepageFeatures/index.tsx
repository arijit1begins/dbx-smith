import type {ReactNode} from 'react';
import clsx from 'clsx';
import Heading from '@theme/Heading';
import styles from './styles.module.css';

type FeatureItem = {
  title: string;
  emoji: string;
  description: ReactNode;
};

const FeatureList: FeatureItem[] = [
  {
    title: 'Strategic Provisioning',
    emoji: '⚒️',
    description: (
      <>
        Choose from Standard, Airgapped, Ghost, Isolated-Net, or Hybrid strategies. 
        DbxSmith forges the exact environment your workflow demands with precision.
      </>
    ),
  },
  {
    title: 'Strict Isolation',
    emoji: '🔒',
    description: (
      <>
        Leverage the Bridge-Destruction hack and True Tmpfs Home Isolation. 
        Keep your host secure and your identity obfuscated in untrusted environments.
      </>
    ),
  },
  {
    title: 'Modular & Ephemeral',
    emoji: '📦',
    description: (
      <>
        Built on Distrobox and Podman, DbxSmith uses modular manifests 
        to ensure zero configuration drift and atomic teardowns for a clean host.
      </>
    ),
  },
];

function Feature({title, emoji, description}: FeatureItem) {
  return (
    <div className={clsx('col col--4')}>
      <div className="text--center">
        <span className={styles.featureEmoji}>{emoji}</span>
      </div>
      <div className="text--center padding-horiz--md">
        <Heading as="h3">{title}</Heading>
        <p>{description}</p>
      </div>
    </div>
  );
}

export default function HomepageFeatures(): ReactNode {
  return (
    <section className={styles.features}>
      <div className="container">
        <div className="row">
          {FeatureList.map((props, idx) => (
            <Feature key={idx} {...props} />
          ))}
        </div>
      </div>
    </section>
  );
}
