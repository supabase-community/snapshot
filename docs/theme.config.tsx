import { useConfig, type DocsThemeConfig } from "nextra-theme-docs";
import { Logo } from "./components/Logo";
import { useRouter } from "next/router";

const themeConfig: DocsThemeConfig = {
  chat: {
    link: "https://app.snaplet.dev/chat",
  },
  head: null,
  logo: <Logo />,
  logoLink: false,
  project: {
    link: "https://github.com/snaplet/docs",
  },
  docsRepositoryBase: "https://github.com/snaplet/docs/tree/main",
  primaryHue: {
    light: 233,
    dark: 233,
  },
  // @ts-expect-error httpEquiv: "Content-Language" is valid
  useNextSeoProps() {
    const { frontMatter } = useConfig();
    const { asPath, defaultLocale, locale } = useRouter();
    const url =
      "https://docs.snaplet.dev" +
      (defaultLocale === locale ? asPath : `/${locale}${asPath}`);
    return {
      titleTemplate: "%s – Snaplet",
      description: frontMatter.description || "Snaplet Documentation",
      additionalLinkTags: [
        {
          href: "/apple-touch-icon.png",
          rel: "apple-touch-icon",
          sizes: "180x180",
        },
        {
          href: "/favicon-32x32.png",
          rel: "icon",
          sizes: "32x32",
          type: "image/png",
        },
        {
          href: "/favicon-16x16.png",
          rel: "icon",
          sizes: "16x16",
          type: "image/png",
        },
        {
          rel: "manifest",
          href: "/site.webmanifest",
        },
      ],
      additionalMetaTags: [
        { content: "en", httpEquiv: "Content-Language" },
        {
          content: "Snaplet Documentation",
          name: "apple-mobile-web-app-title",
        },
        { content: "#b5bdf6", name: "msapplication-TileColor" },
        { content: "/ms-icon-150x150.png", name: "msapplication-TileImage" },
      ],
      openGraph: {
        url,
        images: [
          { url: frontMatter.image || "https://docs.snaplet.dev/og.png" },
        ],
      },
      twitter: {
        cardType: "summary_large_image",
        site: "https://docs.snaplet.dev",
      },
    };
  },
  sidebar: {
    defaultMenuCollapseLevel: 3,
  },
};

export default themeConfig;
