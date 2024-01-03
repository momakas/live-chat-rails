import { createRouter, createWebHistory } from 'vue-router'
import WelcomeView from '../views/WelcomeView'
import ChatroomView from '@/views/ChatroomView.vue'
import userValidate from '../auth/validate'
// import HomeView from '../views/HomeView.vue'

const { error, validate } = userValidate()

// ESLintを無効にしたい時、コメント状態で下記を入れる
// // es-lint-disable-next-line no-used-vars
const requireAuth = async (to, from, next) => {
  const uid = window.localStorage.getItem('uid')
  const client = window.localStorage.getItem('client')
  const accessToken = window.localStorage.getItem('access-token')

  if (!uid || !client || !accessToken) {
    console.log('ログインしていません')
    next({ name: 'WelcomeView'})
    return
  }

  await validate()

  if (error.value) {
    console.log('認証に失敗しました')
    next({ name: 'WelcomeView' })
  } else {
    next()
  }
}

const noRequireAuth = async (to, from, next) => {
  const uid = window.localStorage.getItem('uid')
  const client = window.localStorage.getItem('client')
  const accessToken = window.localStorage.getItem('access-token')

  if (!uid && !client && !accessToken) {
    next()
    return
  }

  await validate()

  if (!error.value) {
    next({ name: 'ChatroomView' })
  } else {
    next()
  }
}

const routes = [
  {
    path: '/',
    name: 'WelcomeView',
    component: WelcomeView,
    beforeEnter: noRequireAuth
  },
  {
    path: '/chatroom',
    name: 'ChatroomView',
    component: ChatroomView,
    beforeEnter: requireAuth
  }
]
// const routes = [
//   {
//     path: '/',
//     name: 'home',
//     component: HomeView
//   },
//   {
//     path: '/about',
//     name: 'about',
//     // route level code-splitting
//     // this generates a separate chunk (about.[hash].js) for this route
//     // which is lazy-loaded when the route is visited.
//     component: () => import(/* webpackChunkName: "about" */ '../views/AboutView.vue')
//   }
// ]

const router = createRouter({
  history: createWebHistory(process.env.BASE_URL),
  routes
})

export default router
