import { css } from '@emotion/react';
import * as React from 'react';

import DocumentationSidebarCollapsible from '~/components/DocumentationSidebarGroup';
import DocumentationSidebarLink from '~/components/DocumentationSidebarLink';
import DocumentationSidebarTitle from '~/components/DocumentationSidebarTitle';
import VersionSelector from '~/components/VersionSelector';
import * as Constants from '~/constants/theme';
import { NavigationRoute, Url } from '~/types/common';

const STYLES_SIDEBAR = css`
  padding: 20px 24px 24px 24px;
  width: 280px;

  @media screen and (max-width: ${Constants.breakpoints.mobile}) {
    width: 100%;
  }
`;

const STYLES_SECTION_CATEGORY = css`
  margin-bottom: 24px;
`;

type SidebarProps = {
  url: Url;
  asPath: string;
  isVersionSelectorHidden: boolean;
  routes: NavigationRoute[];
  version: string;
  onSetVersion: (value: string) => void;
};

type SidebarNodeProps = Pick<SidebarProps, 'url' | 'asPath'> & {
  route: NavigationRoute;
  parentRoute?: NavigationRoute;
};

export default function NewDocumentationSidebar(props: SidebarProps) {
  return (
    <nav css={STYLES_SIDEBAR} data-sidebar>
      {!props.isVersionSelectorHidden && (
        <VersionSelector version={props.version} onSetVersion={props.onSetVersion} />
      )}
      {props.routes.map(section => (
        <NewDocumentationSidebarSection
          key={`section-${section.name}`}
          route={section}
          url={props.url}
          asPath={props.asPath}
        />
      ))}
    </nav>
  );
}

function NewDocumentationSidebarSection(props: SidebarNodeProps) {
  // If the section or group is hidden, we should not render it
  if (props.route.hidden) {
    return null;
  }

  // If a group was passed instead of section, just render that instead
  if (!props.route.children) {
    return <NewDocumentationSidebarGroup {...props} />;
  }

  return (
    <DocumentationSidebarCollapsible
      key={`group-${props.route.name}`}
      url={props.url}
      info={props.route}
      asPath={props.asPath}>
      {props.route.children.map(group => (
        <NewDocumentationSidebarGroup
          {...props}
          key={`group-${props.route.name}`}
          route={group}
          parentRoute={props.route}
        />
      ))}
    </DocumentationSidebarCollapsible>
  );
}

function NewDocumentationSidebarGroup(props: SidebarNodeProps) {
  return (
    <div css={STYLES_SECTION_CATEGORY}>
      {!shouldSkipTitle(props.route, props.parentRoute) && (
        <DocumentationSidebarTitle
          key={props.route.sidebarTitle ? props.route.sidebarTitle : props.route.name}
          info={props.route}
          url={props.url}
          asPath={props.asPath}>
          {props.route.sidebarTitle ? props.route.sidebarTitle : props.route.name}
        </DocumentationSidebarTitle>
      )}
      {(props.route.posts || []).map(page => (
        <DocumentationSidebarLink
          key={`${props.route.name}-${page.name}`}
          info={page}
          url={props.url}
          asPath={props.asPath}>
          {page.sidebarTitle || page.name}
        </DocumentationSidebarLink>
      ))}
    </div>
  );
}

function shouldSkipTitle(info: NavigationRoute, parentGroup?: NavigationRoute) {
  if (info.name === parentGroup?.name) {
    // If the title of the group is Expo SDK and the section within it has the same name
    // then we shouldn't show the title twice. You might want to organize your group like
    // so it is collapsable
    return true;
  } else if (
    info.posts &&
    ((info.posts[0] || {}).sidebarTitle || (info.posts[0] || {}).name) === info.name
  ) {
    // If the first child post in the group has the same name as the group, then hide the
    // group title, lest we be very repetititve
    return true;
  }

  return false;
}
