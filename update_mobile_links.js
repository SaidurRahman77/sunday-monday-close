const { initializeApp, applicationDefault } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');

initializeApp({
  credential: applicationDefault(),
  projectId: 'sunday-monday-close',
});

async function updateMobileLinks() {
  try {
    const projectConfigManager =
      getAuth().projectConfigManager();

    const response =
      await projectConfigManager.updateProjectConfig({
        mobileLinksConfig: {
          domain: 'HOSTING_DOMAIN',
        },
      });

    console.log('Mobile links configuration updated successfully.');
    console.log(response.mobileLinksConfig);
  } catch (error) {
    console.error('Update failed:');
    console.error(error);
  }
}

updateMobileLinks();