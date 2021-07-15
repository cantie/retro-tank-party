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

#include "sg_collision_shape_2d_editor_plugin.h"

#include <editor/editor_node.h>
#include "../scene/2d/sg_collision_shape_2d.h"

void SGCollisionShape2DEditor::edit(Node *p_node) {

}

SGCollisionShape2DEditor::SGCollisionShape2DEditor(EditorNode *p_editor) :
    editor(p_editor),
    undo_redo(p_editor->get_undo_redo()) {

}

bool SGCollisionShape2DEditorPlugin::handles(Object *p_obj) {
    SGCollisionShape2D *node = Object::cast_to<SGCollisionShape2D>(p_obj);
    return (bool)node;
}

void SGCollisionShape2DEditorPlugin::edit(Object *p_obj) {

}

void SGCollisionShape2DEditorPlugin::make_visible(bool visible) {
    if (!visible) {
        edit(nullptr);
    }
}

SGCollisionShape2DEditorPlugin::SGCollisionShape2DEditorPlugin(EditorNode *p_editor) :
    editor(p_editor) {
    collision_shape2d_editor_plugin = memnew(SGCollisionShape2DEditor(p_editor));
    p_editor->get_gui_base()->add_child(collision_shape2d_editor_plugin);
}

SGCollisionShape2DEditorPlugin::~SGCollisionShape2DEditorPlugin() {

}
