import type {ReactNode} from 'react';
import clsx from 'clsx';
import Link from '@docusaurus/Link';
import useDocusaurusContext from '@docusaurus/useDocusaurusContext';
import Layout from '@theme/Layout';
import HomepageFeatures from '@site/src/components/HomepageFeatures';
import Heading from '@theme/Heading';

import styles from './index.module.css';

function HomepageHeader() {
  const {siteConfig} = useDocusaurusContext();
  return (
    <header className={clsx('hero hero--primary', styles.heroBanner)}>
      <div className="container">
        <Heading as="h1" className="hero__title">
          {siteConfig.title}
        </Heading>
        <p className="hero__subtitle">{siteConfig.tagline}</p>
        <div className={styles.buttons}>
          <Link
            className="button button--primary button--lg"
            to="/docs/intro">
            Explore DbxSmith 🛠️
          </Link>
        </div>

      </div>
    </header>
  );
}

export default function Home(): ReactNode {
  const {siteConfig} = useDocusaurusContext();
  return (
    <Layout
      title={`${siteConfig.title} | Isolated Dev Environments`}
      description="DbxSmith: The Forge for Professional-Grade Isolated Developer Environments built on Distrobox and Podman.">
      <HomepageHeader />
      <main>
        <section className="featured-blog-section">
          <div className="container">
            <Heading as="h2" className="text--center margin-bottom--lg">Latest from the Forge</Heading>
            <Link to="/blog/introducing-dbx-smith-v1" className="featured-blog-card">
              <div 
                className="featured-blog-image" 
                style={{backgroundImage: 'url(/dbx-smith/img/dbx-smith-v1-hero.png)'}}
              />
              <div className="featured-blog-content">
                <span className="featured-blog-tag">Official Launch</span>
                <Heading as="h3">Introducing DbxSmith v1.0.0</Heading>
                <p>
                  Read about our journey in building the ultimate provisioning suite for isolated developer environments. 
                  Learn about our modular manifests and airgapped strategies.
                </p>
                <span className="button button--outline button--primary">Read Article →</span>
              </div>
            </Link>
          </div>
        </section>
        <HomepageFeatures />
      </main>
    </Layout>
  );
}
