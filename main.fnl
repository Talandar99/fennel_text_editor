#!/usr/bin/env fennel


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; variables
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(local cursor-position {:x 7 :y 2})
(var file-line-count 0)
(fn get-terminal-size []
  (let [width (: (io.popen "tput cols") :read :*n)
        height (: (io.popen "tput lines") :read :*n)]
    (values width height)))
(local (terminal-width terminal-height) (get-terminal-size))
(var file-content {})
(var line-count-padding 0)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; terminal non block mode
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn set-non-blocking-mode [] (os.execute "stty -icanon -echo"))
(fn reset-terminal-mode [] (os.execute "stty icanon echo"))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; exit
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn exit-zero [] (io.write "\027[2J\027[H") (reset-terminal-mode) (os.exit 0))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; handling keys
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn handle-key-press [key]
  (if (= key "\027") (exit-zero)
      (= key :h) (set cursor-position.x (- cursor-position.x 1))
      (= key :j) (set cursor-position.y (+ cursor-position.y 1))
      (= key :k) (set cursor-position.y (- cursor-position.y 1))
      (= key :l) (set cursor-position.x (+ cursor-position.x 1)))
  (when (< cursor-position.y 2) (set cursor-position.y 2))
  (when (< cursor-position.x 5) (set cursor-position.x 5))
  (when (> cursor-position.y file-line-count)
    (set cursor-position.y (+ file-line-count 1))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; math
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn count-digits [number]
  (var count 0)
  (while (not= number 0)
    (set-forcibly! number (math.floor (/ number 10)))
    (set count (+ count 1)))
  count)

(fn count-digit-difference [number1 number2]
  (var count1 0)
  (var count2 0)
  (var temp1 number1)
  (while (not= temp1 0)
    (set temp1 (math.floor (/ temp1 10)))
    (set count1 (+ count1 1)))
  (var temp2 number2)
  (while (not= temp2 0)
    (set temp2 (math.floor (/ temp2 10)))
    (set count2 (+ count2 1)))
  (math.abs (- count1 count2)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; readfile
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn readfile []
  (when (< (length arg) 1) (print "missing filename") (exit-zero))
  (local filename (. arg 1))
  (local file (io.open filename :r))
  (if file (let [lines {}]
             (each [line (file:lines)] (table.insert lines line)
               (set file-line-count (+ file-line-count 1)))
             (set file-content lines)
             (set line-count-padding (+ (count-digits file-line-count) 1))
             (file:close)) (print (.. "Can't open" filename))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; draw
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn draw []
  (let [lines file-content]
    (each [i line (ipairs lines)]
      (when (= i 1)
        (var l "─")
        (for [i-l 1 (- 95 1)]
          (if (= i-l line-count-padding) (set l (.. l "┬"))
              (set l (.. l "─"))))
        (print l))
      (local pad (count-digit-difference file-line-count i))
      (var spaces "")
      (for [j 1 pad] (set spaces (.. spaces " ")))
      (print (.. i spaces " │ " line))
      (when (= i file-line-count)
        (var l "─")
        (for [i-l 1 (- 95 1)]
          (if (= i-l line-count-padding) (set l (.. l "┴"))
              (set l (.. l "─"))))
        (print l)
        (print "MODE: NORMAL")
        (var l "─")
        (for [i-l 1 (- 95 1)] (set l (.. l "─")))
        (print l)
        (print (.. "t height:        " terminal-height))
        (print (.. "t width:         " terminal-width))
        (print (.. "file line count: " file-line-count))))))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;init
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn init [] (set-non-blocking-mode) (io.write "\027[2J\027[H") (readfile)
  (print (.. "t height:        " terminal-height))
  (print (.. "t width:         " terminal-width))
  (print (.. "file line count: " file-line-count)))
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; main
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(fn main []
  (init)
  (while true (io.write "\027[2J\027[H") (draw)
    (io.write (string.format "\027[%d;%dH" cursor-position.y cursor-position.x))
    (local key (io.read 1))
    (when key (handle-key-press key))))
(main)	
