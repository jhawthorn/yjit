# frozen_string_literal: false
require 'test/unit'

class TestNumeric < Test::Unit::TestCase
  def test_coerce
    a, b = 1.coerce(2)
    assert_kind_of(Integer, a)
    assert_kind_of(Integer, b)

    a, b = 1.coerce(2.0)
    assert_equal(Float, a.class)
    assert_equal(Float, b.class)

    assert_raise(TypeError) { -Numeric.new }

    assert_raise_with_message(TypeError, /can't be coerced into /) {1+:foo}
    assert_raise_with_message(TypeError, /can't be coerced into /) {1&:foo}
    assert_raise_with_message(TypeError, /can't be coerced into /) {1|:foo}
    assert_raise_with_message(TypeError, /can't be coerced into /) {1^:foo}

    assert_raise_with_message(TypeError, /:\u{3042}/) {1+:"\u{3042}"}
    assert_raise_with_message(TypeError, /:\u{3042}/) {1&:"\u{3042}"}
    assert_raise_with_message(TypeError, /:\u{3042}/) {1|:"\u{3042}"}
    assert_raise_with_message(TypeError, /:\u{3042}/) {1^:"\u{3042}"}
    assert_raise_with_message(TypeError, /:"\\u3042"/) {1+:"\u{3042}"}
    assert_raise_with_message(TypeError, /:"\\u3042"/) {1&:"\u{3042}"}
    assert_raise_with_message(TypeError, /:"\\u3042"/) {1|:"\u{3042}"}
    assert_raise_with_message(TypeError, /:"\\u3042"/) {1^:"\u{3042}"}
    assert_raise_with_message(TypeError, /:\u{3044}/) {1+"\u{3044}".to_sym}
    assert_raise_with_message(TypeError, /:\u{3044}/) {1&"\u{3044}".to_sym}
    assert_raise_with_message(TypeError, /:\u{3044}/) {1|"\u{3044}".to_sym}
    assert_raise_with_message(TypeError, /:\u{3044}/) {1^"\u{3044}".to_sym}

    bug10711 = '[ruby-core:67405] [Bug #10711]'
    exp = "1.2 can't be coerced into Integer"
    assert_raise_with_message(TypeError, exp, bug10711) { 1 & 1.2 }
  end

  def test_dummynumeric
    a = Class.new(Numeric) do
      def coerce(x); nil; end
    end.new
    assert_raise(TypeError) { -a }
    assert_nil(1 <=> a)
    assert_raise(ArgumentError) { 1 <= a }

    a = Class.new(Numeric) do
      def coerce(x); 1.coerce(x); end
    end.new
    assert_equal(2, 1 + a)
    assert_equal(0, 1 <=> a)
    assert_operator(1, :<=, a)

    a = Class.new(Numeric) do
      def coerce(x); [x, 1]; end
    end.new
    assert_equal(-1, -a)

    a = Class.new(Numeric) do
      def coerce(x); raise StandardError, "my error"; end
    end.new
    assert_raise_with_message(StandardError, "my error") { 1 + a }
    assert_raise_with_message(StandardError, "my error") { 1 < a }

    a = Class.new(Numeric) do
      def coerce(x); :bad_return_value; end
    end.new
    assert_raise_with_message(TypeError, "coerce must return [x, y]") { 1 + a }
    assert_raise_with_message(TypeError, "coerce must return [x, y]") { 1 < a }
  end

  def test_singleton_method
    a = Numeric.new
    assert_raise_with_message(TypeError, /foo/) { def a.foo; end }
    assert_raise_with_message(TypeError, /\u3042/) { eval("def a.\u3042; end") }
  end

  def test_dup
    a = Numeric.new
    assert_same a, a.dup
  end

  def test_clone
    a = Numeric.new
    assert_same a, a.clone
    assert_raise(ArgumentError) {a.clone(freeze: false)}

    c = EnvUtil.labeled_class("\u{1f4a9}", Numeric)
    assert_raise_with_message(ArgumentError, /\u{1f4a9}/) do
      c.new.clone(freeze: false)
    end
  end

  def test_quo
    a = Numeric.new
    assert_raise(TypeError) {a.quo(1)}
  end

  def test_quo_ruby_core_41575
    rat = 84.quo(1)
    x = Class.new(Numeric) do
      define_method(:to_r) { rat }
    end.new
    assert_equal(2.quo(1), x.quo(42), '[ruby-core:41575]')
  end

  def test_divmod
=begin
    x = Class.new(Numeric) do
      def /(x); 42.0; end
      def %(x); :mod; end
    end.new

    assert_equal(42, x.div(1))
    assert_equal(:mod, x.modulo(1))
    assert_equal([42, :mod], x.divmod(1))
=end

    assert_kind_of(Integer, 11.divmod(3.5).first, '[ruby-dev:34006]')
  end

  def test_real_p
    assert_predicate(Numeric.new, :real?)
  end

  def test_integer_p
    assert_not_predicate(Numeric.new, :integer?)
  end

  def test_abs
    a = Class.new(Numeric) do
      def -@; :ok; end
      def <(x); true; end
    end.new

    assert_equal(:ok, a.abs)

    a = Class.new(Numeric) do
      def <(x); false; end
    end.new

    assert_equal(a, a.abs)
  end

  def test_zero_p
    a = Class.new(Numeric) do
      def ==(x); true; end
    end.new

    assert_predicate(a, :zero?)
  end

  def test_nonzero_p
    a = Class.new(Numeric) do
      def zero?; true; end
    end.new
    assert_nil(a.nonzero?)

    a = Class.new(Numeric) do
      def zero?; false; end
    end.new
    assert_equal(a, a.nonzero?)
  end

  def test_positive_p
    a = Class.new(Numeric) do
      def >(x); true; end
    end.new
    assert_predicate(a, :positive?)

    a = Class.new(Numeric) do
      def >(x); false; end
    end.new
    assert_not_predicate(a, :positive?)
  end

  def test_negative_p
    a = Class.new(Numeric) do
      def <(x); true; end
    end.new
    assert_predicate(a, :negative?)

    a = Class.new(Numeric) do
      def <(x); false; end
    end.new
    assert_not_predicate(a, :negative?)
  end

  def test_to_int
    a = Class.new(Numeric) do
      def to_i; :ok; end
    end.new

    assert_equal(:ok, a.to_int)
  end

  def test_cmp
    a = Numeric.new
    assert_equal(0, a <=> a)
    assert_nil(a <=> :foo)
  end

  def test_floor_ceil_round_truncate
    a = Class.new(Numeric) do
      def to_f; 1.5; end
    end.new

    assert_equal(1, a.floor)
    assert_equal(2, a.ceil)
    assert_equal(2, a.round)
    assert_equal(1, a.truncate)

    a = Class.new(Numeric) do
      def to_f; 1.4; end
    end.new

    assert_equal(1, a.floor)
    assert_equal(2, a.ceil)
    assert_equal(1, a.round)
    assert_equal(1, a.truncate)

    a = Class.new(Numeric) do
      def to_f; -1.5; end
    end.new

    assert_equal(-2, a.floor)
    assert_equal(-1, a.ceil)
    assert_equal(-2, a.round)
    assert_equal(-1, a.truncate)
  end

  def test_floor_ceil_ndigits
    bug17183 = "[ruby-core:100090]"
    f = 291.4
    31.times do |i|
      assert_equal(291.4, f.floor(i+1), bug17183)
      assert_equal(291.4, f.ceil(i+1), bug17183)
    end
  end

  def assert_step(expected, (from, *args), inf: false)
    kw = args.last.is_a?(Hash) ? args.pop : {}
    enum = from.step(*args, **kw)
    size = enum.size
    xsize = expected.size

    if inf
      assert_send [size, :infinite?], "step size: +infinity"
      assert_send [size, :>, 0], "step size: +infinity"

      a = []
      from.step(*args, **kw) { |x| a << x; break if a.size == xsize }
      assert_equal expected, a, "step"

      a = []
      enum.each { |x| a << x; break if a.size == xsize }
      assert_equal expected, a, "step enumerator"
    else
      assert_equal expected.size, size, "step size"

      a = []
      from.step(*args, **kw) { |x| a << x }
      assert_equal expected, a, "step"

      a = []
      enum.each { |x| a << x }
      assert_equal expected, a, "step enumerator"
    end
  end

  def test_step
    bignum = RbConfig::LIMITS['FIXNUM_MAX'] + 1
    assert_raise(ArgumentError) { 1.step(10, 1, 0) { } }
    assert_raise(ArgumentError) { 1.step(10, 1, 0).size }
    assert_raise(ArgumentError) { 1.step(10, 0) { } }
    assert_raise(ArgumentError) { 1.step(10, "1") { } }
    assert_raise(ArgumentError) { 1.step(10, "1").size }
    assert_raise(TypeError) { 1.step(10, nil) { } }
    assert_nothing_raised { 1.step(10, nil).size }
    assert_nothing_raised { 1.step(by: nil) }
    assert_nothing_raised { 1.step(by: nil).size }

    assert_kind_of(Enumerator::ArithmeticSequence, 1.step(10))
    assert_kind_of(Enumerator::ArithmeticSequence, 1.step(10, 2))
    assert_kind_of(Enumerator::ArithmeticSequence, 1.step(10, by: 2))
    assert_kind_of(Enumerator::ArithmeticSequence, 1.step(by: 2))
    assert_kind_of(Enumerator::ArithmeticSequence, 1.step(by: 2, to: nil))
    assert_kind_of(Enumerator::ArithmeticSequence, 1.step(by: 2, to: 10))
    assert_kind_of(Enumerator::ArithmeticSequence, 1.step(by: -1))

    bug9811 = '[ruby-dev:48177] [Bug #9811]'
    assert_raise(ArgumentError, bug9811) { 1.step(10, foo: nil) {} }
    assert_raise(ArgumentError, bug9811) { 1.step(10, foo: nil).size }
    assert_raise(ArgumentError, bug9811) { 1.step(10, to: 11) {} }
    assert_raise(ArgumentError, bug9811) { 1.step(10, to: 11).size }
    assert_raise(ArgumentError, bug9811) { 1.step(10, 1, by: 11) {} }
    assert_raise(ArgumentError, bug9811) { 1.step(10, 1, by: 11).size }

    feature15573 = "[ruby-core:91324] [Feature #15573]"
    assert_raise(ArgumentError, feature15573) { 1.step(10, 0) }
    assert_raise(ArgumentError, feature15573) { 1.step(10, by: 0) }
    assert_raise(ArgumentError, feature15573) { 1.step(10, 0) { break } }
    assert_raise(ArgumentError, feature15573) { 1.step(10, by: 0) { break } }
    assert_raise(ArgumentError, feature15573) { 42.step(by: 0, to: -Float::INFINITY) }
    assert_raise(ArgumentError, feature15573) { 42.step(by: 0, to: 42.5) }
    assert_raise(ArgumentError, feature15573) { 4.2.step(by: 0.0) }
    assert_raise(ArgumentError, feature15573) { 4.2.step(by: -0.0) }
    assert_raise(ArgumentError, feature15573) { 42.step(by: 0.0, to: 44) }
    assert_raise(ArgumentError, feature15573) { 42.step(by: 0.0, to: 0) }
    assert_raise(ArgumentError, feature15573) { 42.step(by: -0.0, to: 44) }
    assert_raise(ArgumentError, feature15573) { bignum.step(by: 0) }
    assert_raise(ArgumentError, feature15573) { bignum.step(by: 0.0) }
    assert_raise(ArgumentError, feature15573) { bignum.step(by: 0, to: bignum+1) }
    assert_raise(ArgumentError, feature15573) { bignum.step(by: 0, to: 0) }

    e = 1.step(10, {by: "1"})
    assert_raise(TypeError) {e.next}
    assert_raise(TypeError) {e.size}

    assert_equal(bignum*2+1, (-bignum).step(bignum, 1).size)
    assert_equal(bignum*2, (-bignum).step(bignum-1, 1).size)

    assert_equal(10+1, (0.0).step(10.0, 1.0).size)

    i, bigflo = 1, bignum.to_f
    i <<= 1 until (bigflo - i).to_i < bignum
    bigflo -= i >> 1
    assert_equal(bigflo.to_i, (0.0).step(bigflo-1.0, 1.0).size)

    assert_step [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, 10]
    assert_step [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, to: 10]
    assert_step [1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [1, to: 10, by: nil]
    assert_step [1, 3, 5, 7, 9], [1, 10, 2]
    assert_step [1, 3, 5, 7, 9], [1, to: 10, by: 2]

    assert_step [10, 8, 6, 4, 2], [10, 1, -2]
    assert_step [10, 8, 6, 4, 2], [10, to: 1, by: -2]
    assert_step [1.0, 3.0, 5.0, 7.0, 9.0], [1.0, 10.0, 2.0]
    assert_step [1.0, 3.0, 5.0, 7.0, 9.0], [1.0, to: 10.0, by: 2.0]
    assert_step [1], [1, 10, bignum]
    assert_step [1], [1, to: 10, by: bignum]

    assert_step [], [2, 1, 3]
    assert_step [], [-2, -1, -3]
    assert_step [10], [10, 1, -bignum]

    assert_step [], [1, 0, Float::INFINITY]
    assert_step [], [0, 1, -Float::INFINITY]
    assert_step [10], [10, to: 1, by: -bignum]

    assert_step [10, 11, 12, 13], [10], inf: true
    assert_step [10, 9, 8, 7], [10, by: -1], inf: true
    assert_step [10, 9, 8, 7], [10, by: -1, to: nil], inf: true
  end

  def test_step_bug15537
    assert_step [10.0, 8.0, 6.0, 4.0, 2.0], [10.0, 1, -2]
    assert_step [10.0, 8.0, 6.0, 4.0, 2.0], [10.0, to: 1, by: -2]
    assert_step [10.0, 8.0, 6.0, 4.0, 2.0], [10.0, 1, -2]
    assert_step [10.0, 8.0, 6.0, 4.0, 2.0], [10, to: 1.0, by: -2]
    assert_step [10.0, 8.0, 6.0, 4.0, 2.0], [10, 1.0, -2]

    assert_step [10.0, 9.0, 8.0, 7.0], [10, by: -1.0], inf: true
    assert_step [10.0, 9.0, 8.0, 7.0], [10, by: -1.0, to: nil], inf: true
    assert_step [10.0, 9.0, 8.0, 7.0], [10, nil, -1.0], inf: true
    assert_step [10.0, 9.0, 8.0, 7.0], [10.0, by: -1], inf: true
    assert_step [10.0, 9.0, 8.0, 7.0], [10.0, nil, -1], inf: true
  end

  def test_num2long
    assert_raise(TypeError) { 1 & nil }
    assert_raise(TypeError) { 1 & 1.0 }
    assert_raise(TypeError) { 1 & 2147483648.0 }
    assert_raise(TypeError) { 1 & 9223372036854777856.0 }
    o = Object.new
    def o.to_int; 1; end
    assert_raise(TypeError) { assert_equal(1, 1 & o) }
  end

  def test_eql
    assert_equal(1, 1.0)
    assert_not_operator(1, :eql?, 1.0)
    assert_not_operator(1, :eql?, 2)
  end

  def test_coerced_remainder
    assert_separately([], <<-'end;')
      x = Class.new do
        def coerce(a) [self, a]; end
        def %(a) self; end
      end.new
      assert_raise(ArgumentError) {1.remainder(x)}
    end;
  end

  def test_remainder_infinity
    assert_equal(4, 4.remainder(Float::INFINITY))
    assert_equal(4, 4.remainder(-Float::INFINITY))
    assert_equal(-4, -4.remainder(Float::INFINITY))
    assert_equal(-4, -4.remainder(-Float::INFINITY))

    assert_equal(4.2, 4.2.remainder(Float::INFINITY))
    assert_equal(4.2, 4.2.remainder(-Float::INFINITY))
    assert_equal(-4.2, -4.2.remainder(Float::INFINITY))
    assert_equal(-4.2, -4.2.remainder(-Float::INFINITY))
  end

  def test_comparison_comparable
    bug12864 = '[ruby-core:77713] [Bug #12864]'

    myinteger = Class.new do
      include Comparable

      def initialize(i)
        @i = i.to_i
      end
      attr_reader :i

      def <=>(other)
        @i <=> (other.is_a?(self.class) ? other.i : other)
      end
    end

    all_assertions(bug12864) do |a|
      [5, 2**62, 2**61].each do |i|
        a.for("%#x"%i) do
          m = myinteger.new(i)
          assert_equal(i, m)
          assert_equal(m, i)
        end
      end
    end
  end

  def test_pow
    assert_equal(2**3, 2.pow(3))
    assert_equal(2**-1, 2.pow(-1))
    assert_equal(2**0.5, 2.pow(0.5))
    assert_equal((-1)**0.5, -1.pow(0.5))
    assert_equal(3**3 % 8, 3.pow(3, 8))
    assert_equal(3**3 % -8, 3.pow(3,-8))
    assert_equal(3**2 % -2, 3.pow(2,-2))
    assert_equal((-3)**3 % 8, -3.pow(3,8))
    assert_equal((-3)**3 % -8, -3.pow(3,-8))
    assert_equal(5**2 % -8, 5.pow(2,-8))
    assert_equal(4481650795473624846969600733813414725093,
                 2120078484650058507891187874713297895455.
                    pow(5478118174010360425845660566650432540723,
                        5263488859030795548286226023720904036518))

    assert_equal(12, 12.pow(1, 10000000000), '[Bug #14259]')
    assert_equal(12, 12.pow(1, 10000000001), '[Bug #14259]')
    assert_equal(12, 12.pow(1, 10000000002), '[Bug #14259]')
    assert_equal(17298641040, 12.pow(72387894339363242, 243682743764), '[Bug #14259]')

    integers = [-2, -1, 0, 1, 2, 3, 6, 1234567890123456789]
    integers.each do |i|
      assert_equal(0, i.pow(0, 1), '[Bug #17257]')
      assert_equal(1, i.pow(0, 2))
      assert_equal(1, i.pow(0, 3))
      assert_equal(1, i.pow(0, 6))
      assert_equal(1, i.pow(0, 1234567890123456789))

      assert_equal(0,  i.pow(0, -1))
      assert_equal(-1, i.pow(0, -2))
      assert_equal(-2, i.pow(0, -3))
      assert_equal(-5, i.pow(0, -6))
      assert_equal(-1234567890123456788, i.pow(0, -1234567890123456789))
    end

    assert_equal(0,  0.pow(2, 1))
    assert_equal(0,  0.pow(3, 1))
    assert_equal(0,  2.pow(3, 1))
    assert_equal(0, -2.pow(3, 1))
  end

end
