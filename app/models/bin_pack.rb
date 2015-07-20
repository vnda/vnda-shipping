module BinPack
  extend self

  class Box
    attr_reader :w, :h, :l
    MIN_LENGTH = 16
    MIN_WIDTH = 11
    MIN_HEIGHT = 2

    def initialize(w, h, l)
      @w, @h, @l = [w, h, l].map(&:to_f)
      @w = MIN_WIDTH if @w < MIN_WIDTH
      @h = MIN_HEIGHT if @h < MIN_HEIGHT
      @l = MIN_LENGTH if @l < MIN_LENGTH
    end

    def vol
      w * h * l
    end

    # make heigh the smallest dimension, width the median and length the biggest
    def orient
      nh, nw, nl = [w, h, l].sort
      self.class.new(nw, nh, nl)
    end
  end

  # This algorithim calculates the most optimistic guess of the box size,
  # where all items fit perfectly (100% space utilization)
  def min_bounding_box(boxes)
    boxes = boxes.map(&:orient)
    largest = boxes.reduce(Box.new(0, 0, 0)) do |max, box|
      Box.new(box.w > max.w ? box.w : max.w,
              box.h > max.h ? box.h : max.h,
              box.l > max.l ? box.l : max.l)
    end
    volume = boxes.reduce(0) { |total, box| total + box.vol }
    Box.new(largest.w, volume / (largest.w * largest.l), largest.l)
  end
end
