/*************************************************************************/
/* Copyright (c) 2021 David Snopek                                       */
/*                                                                       */
/* Permission is hereby granted, free of charge, to any person obtaining */
/* a copy of this software and associated documentation files (the       */
/* "Software"), to deal in the Software without restriction, including   */
/* without limitation the rights to use, copy, modify, merge, publish,   */
/* distribute, sublicense, and/or sell copies of the Software, and to    */
/* permit persons to whom the Software is furnished to do so, subject to */
/* the following conditions:                                             */
/*                                                                       */
/* The above copyright notice and this permission notice shall be        */
/* included in all copies or substantial portions of the Software.       */
/*                                                                       */
/* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,       */
/* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF    */
/* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.*/
/* IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY  */
/* CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,  */
/* TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE     */
/* SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                */
/*************************************************************************/

#ifndef SG_FIXED_VECTOR2_H
#define SG_FIXED_VECTOR2_H

#include <core/reference.h>

#include "../internal/sg_fixed_math_internal.h"

class SGFixedVector2 : public Reference {

    GDCLASS(SGFixedVector2, Reference);

    fixed_vector2 value;

protected:
    static void _bind_methods();

public:

    _FORCE_INLINE_ int64_t get_x() const { return value.x.value; }
    _FORCE_INLINE_ int64_t get_y() const { return value.y.value; }

    void set_x(int64_t p_x) {
        value.x.value = p_x;
        emit_signal("changed");
    }

    void set_y(int64_t p_y) {
        value.y.value = p_y;
        emit_signal("changed");
    }

    void clear() {
        value.x.value = 0;
        value.y.value = 0;
        emit_signal("changed");
    }

    Ref<SGFixedVector2> add(const Ref<SGFixedVector2> &p_other) const;
    void iadd(const Ref<SGFixedVector2>& p_other);
    Ref<SGFixedVector2> sub(const Ref<SGFixedVector2> &p_other) const;
    void isub(const Ref<SGFixedVector2>& p_other);
    Ref<SGFixedVector2> mul(const Ref<SGFixedVector2> &p_other) const;
    void imul(const Ref<SGFixedVector2>& p_other);
    Ref<SGFixedVector2> div(const Ref<SGFixedVector2> &p_other) const;
    void idiv(const Ref<SGFixedVector2>& p_other);

    Ref<SGFixedVector2> addf(int64_t p_fixed) const;
    void iaddf(int64_t p_fixed);
    Ref<SGFixedVector2> subf(int64_t p_fixed) const;
    void isubf(int64_t p_fixed);
    Ref<SGFixedVector2> mulf(int64_t p_fixed) const;
    void imulf(int64_t p_fixed);
    Ref<SGFixedVector2> divf(int64_t p_fixed) const;
    void idivf(int64_t p_fixed);

    Ref<SGFixedVector2> abs() const;
    Ref<SGFixedVector2> normalized() const;
    int64_t length() const;

    void rotate(int64_t p_rotation);
    Ref<SGFixedVector2> rotated(int64_t p_rotation) const;

    Ref<SGFixedVector2> slide(const Ref<SGFixedVector2> &p_normal) const;
    Ref<SGFixedVector2> bounce(const Ref<SGFixedVector2> &p_normal) const;
    Ref<SGFixedVector2> reflect(const Ref<SGFixedVector2> &p_normal) const;

    void from_float(Vector2 p_float_vector);
    Vector2 to_float() const;

    // Won't trigger the "changed" signal. Meant only for internal use.
    _FORCE_INLINE_ fixed_vector2 get_internal() const { return value; }
    _FORCE_INLINE_ void set_internal(fixed_vector2 p_value) { value = p_value; }

    _FORCE_INLINE_ static Ref<SGFixedVector2> from_internal(const fixed_vector2 &p_internal) {
        return Ref<SGFixedVector2>(memnew(SGFixedVector2(p_internal)));
    }

    SGFixedVector2() { }
    SGFixedVector2(const fixed_vector2& p_internal_vector) {
        value = p_internal_vector;
    }

    ~SGFixedVector2() { };

};

#endif