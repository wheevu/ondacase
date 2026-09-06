(local W 720)
(local H 720)
(local FOOTER_Y 680)
(local ACTION_BOTTOM 648)

(fn calc [win-w win-h]
  (let [scale (math.min (/ win-w W) (/ win-h H))
        sw (* W scale)
        sh (* H scale)
        ox (/ (- win-w sw) 2)
        oy (/ (- win-h sh) 2)]
    {:scale scale :ox ox :oy oy :sw sw :sh sh}))

(fn to-logical [sx sy win-w win-h]
  (let [l (calc win-w win-h)]
    [(/ (- sx l.ox) l.scale) (/ (- sy l.oy) l.scale)]))

(fn in-logical? [x y]
  (and (>= x 0) (<= x W) (>= y 0) (<= y H)))

{: W : H : FOOTER_Y : ACTION_BOTTOM : calc : to-logical : in-logical?}
