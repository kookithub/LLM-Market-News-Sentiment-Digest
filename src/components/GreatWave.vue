<script setup>
// Hero artwork in the style of an ukiyo-e woodblock print (after Hokusai's Great Wave):
// a curling Prussian-blue wave with foam "claws", spray, a boat and a small Mt. Fuji.
// Decorative only. Colors come from CSS classes (.gw-*) in style.css.
import { useId } from 'vue'

const uid = useId()
const clipId = `gw-body-${uid}`
const clawId = `gw-claw-${uid}`

// [x, y, rotation°, scale] — foam claws along the crest and the curl.
const CREST_CLAWS = [
  [126, 134, -50, 0.9], [154, 108, -45, 0.95], [184, 82, -35, 1], [214, 60, -25, 1.1], [244, 46, -15, 1.1],
  [276, 38, -5, 1.15], [308, 36, 5, 1.15], [340, 40, 15, 1.2], [368, 50, 30, 1.2], [394, 66, 50, 1.2],
  [414, 88, 70, 1.15], [428, 114, 95, 1.1], [430, 140, 120, 1.05], [420, 162, 150, 1], [400, 176, 180, 1],
  [376, 178, 210, 0.95],
]
const SWELL_CLAWS = [
  [540, 302, 0, 0.8], [570, 296, -10, 0.8], [604, 292, -8, 0.8], [700, 298, 6, 0.8], [790, 310, 9, 0.8],
  [890, 322, 6, 0.8], [990, 330, 3, 0.8], [1090, 333, 0, 0.8], [1190, 334, 0, 0.8],
  [20, 306, -20, 0.8], [48, 298, 0, 0.8], [78, 302, 20, 0.8], [104, 316, 45, 0.8],
]
const SPRAY = [
  [452, 120, 2.6], [466, 146, 2], [444, 168, 2.4], [478, 182, 1.8], [458, 204, 2.2], [490, 214, 1.6], [436, 226, 2],
  [470, 236, 1.6], [500, 160, 1.6], [512, 196, 1.4], [424, 196, 2.2], [448, 92, 1.8], [486, 108, 1.4], [520, 230, 1.4],
  [410, 210, 1.8], [394, 232, 1.6], [430, 250, 1.4], [500, 250, 1.2], [462, 266, 1.2], [532, 176, 1.2],
]
</script>

<template>
  <svg class="great-wave" viewBox="0 0 640 380" preserveAspectRatio="xMidYMax meet" aria-hidden="true" focusable="false">
    <defs>
      <clipPath :id="clipId">
        <path
          d="M0 380 L0 270 C30 236 70 172 125 118 C178 66 250 34 322 38 C384 42 428 76 438 118 C446 150 428 180 396 186 C368 190 350 170 360 148 C368 132 388 132 394 144 C386 118 352 106 322 116 C278 130 258 178 262 230 C266 282 298 330 342 380 Z"
        />
      </clipPath>
      <path :id="clawId" d="M0 0 C4 -12 18 -14 24 -4 C18 -8 11 -7 9 -1 C14 -3 18 0 18 5 C12 2 5 4 0 0 Z" />
    </defs>

    <!-- Mt. Fuji on the horizon -->
    <path class="gw-fuji gw-ink" d="M452 312 L500 258 L548 312 Z" />
    <path class="gw-foam gw-ink" d="M486 274 L500 258 L514 274 L508 271 L503 278 L497 270 L492 277 Z" />

    <!-- Right swell. Drawn past the viewBox (x > 640) so, on wide screens, the sea
         continues under the title panel; the .print frame clips it. -->
    <path class="gw-mid gw-ink" d="M330 380 C390 350 450 316 520 306 C580 298 640 292 720 302 C860 322 1000 334 1300 334 L1300 380 Z" />
    <path class="gw-line" d="M420 380 C450 352 500 334 560 326 C640 320 760 340 1300 352 M500 380 C530 360 580 348 640 344 C760 350 900 366 1300 370" />
    <path class="gw-crest" d="M360 362 C420 330 470 312 530 304 C580 298 640 292 720 302 C860 322 1000 334 1300 334" />

    <!-- The great wave -->
    <g :clip-path="`url(#${clipId})`">
      <rect class="gw-dark" x="0" y="0" width="640" height="380" />
      <path
        class="gw-line gw-line--thick"
        d="M20 360 C50 280 100 190 170 128 M70 380 C100 300 140 220 210 150 M130 380 C150 310 190 236 250 180 M196 380 C210 320 236 262 268 220 M330 60 C380 66 410 96 414 128"
      />
    </g>
    <path
      class="gw-outline"
      d="M0 270 C30 236 70 172 125 118 C178 66 250 34 322 38 C384 42 428 76 438 118 C446 150 428 180 396 186 C368 190 350 170 360 148 C368 132 388 132 394 144 C386 118 352 106 322 116 C278 130 258 178 262 230 C266 282 298 330 342 380"
    />
    <path class="gw-crest gw-crest--wide" d="M40 250 C80 190 140 110 220 62 C270 36 340 34 392 64 C430 88 440 140 410 170" />
    <path class="gw-line" d="M60 252 C98 196 154 122 228 76 C276 50 336 50 384 76" />
    <use
      v-for="([x, y, r, s], i) in CREST_CLAWS"
      :key="`c${i}`"
      :href="`#${clawId}`"
      class="gw-foam gw-ink"
      :transform="`translate(${x} ${y}) rotate(${r}) scale(${s})`"
    />
    <use :href="`#${clawId}`" class="gw-light gw-ink" transform="translate(372 146) rotate(200) scale(0.8)" />
    <use :href="`#${clawId}`" class="gw-light gw-ink" transform="translate(386 160) rotate(232) scale(0.7)" />

    <!-- Spray -->
    <circle v-for="([x, y, r], i) in SPRAY" :key="`s${i}`" :cx="x" :cy="y" :r="r" class="gw-foam" />

    <!-- Boat -->
    <path class="gw-foam gw-ink" d="M150 330 C210 316 290 318 340 330 C290 340 210 342 150 330 Z" />
    <path class="gw-ink-line" d="M180 330 L320 330 M200 326 L200 334 M230 325 L230 335 M260 325 L260 335 M290 326 L290 334" />

    <!-- Foreground swell, left -->
    <path class="gw-dark gw-ink" d="M0 380 L0 318 C34 296 84 300 118 330 C132 344 136 362 132 380 Z" />
    <path class="gw-line" d="M0 352 C30 334 66 336 96 356" />
    <path class="gw-crest" d="M0 318 C34 296 84 300 118 330" />
    <use
      v-for="([x, y, r, s], i) in SWELL_CLAWS"
      :key="`w${i}`"
      :href="`#${clawId}`"
      class="gw-foam gw-ink"
      :transform="`translate(${x} ${y}) rotate(${r}) scale(${s})`"
    />
  </svg>
</template>
