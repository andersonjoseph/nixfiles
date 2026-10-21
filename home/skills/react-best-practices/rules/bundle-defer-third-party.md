---
title: Defer Non-Critical Third-Party Libraries
impact: MEDIUM
impactDescription: loads after hydration
tags: bundle, third-party, analytics, defer
---

## Defer Non-Critical Third-Party Libraries

Analytics, logging, and error tracking don't block user interaction. Load them after the app is interactive so they never compete with first paint or hydration.

**Incorrect (blocks initial bundle):**

```tsx
import { Analytics } from '@vercel/analytics/react'

export function App() {
  return (
    <>
      <Routes />
      <Analytics />
    </>
  )
}
```

**Correct (loads after mount via React.lazy):**

```tsx
import { lazy, Suspense, useEffect, useState } from 'react'

const Analytics = lazy(() =>
  import('@vercel/analytics/react').then(m => ({ default: m.Analytics }))
)

export function App() {
  const [showAnalytics, setShowAnalytics] = useState(false)
  useEffect(() => {
    // Defer until after the app is interactive
    setShowAnalytics(true)
  }, [])

  return (
    <>
      <Routes />
      {showAnalytics && (
        <Suspense fallback={null}>
          <Analytics />
        </Suspense>
      )}
    </>
  )
}
```
