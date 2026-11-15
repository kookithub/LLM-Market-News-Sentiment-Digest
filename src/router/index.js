import { createRouter, createWebHistory } from 'vue-router'
import { appConfig } from '../config/app.config.js'

const routes = [
  { path: '/', name: 'dashboard', component: () => import('../views/DashboardView.vue'), meta: { title: 'Dashboard' } },
  { path: '/new', name: 'add-asset', component: () => import('../views/AddAssetView.vue'), meta: { title: 'Add asset' } },
  { path: '/asset/:id', name: 'asset', component: () => import('../views/AssetDetailView.vue'), props: true, meta: { title: 'Asset' } },
  { path: '/:pathMatch(.*)*', redirect: '/' },
]

export const router = createRouter({
  history: createWebHistory(import.meta.env.BASE_URL),
  routes,
  scrollBehavior: () => ({ top: 0 }),
})

router.afterEach((to) => {
  document.title = to.meta.title ? `${to.meta.title} · ${appConfig.app.name}` : appConfig.app.name
})
