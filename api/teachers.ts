
import { getSupabaseAdmin } from '../lib/supabase-admin';
import crypto from 'crypto';

export default async function handler(req, res) {
  const { pathname } = new URL(req.url, `http://${req.headers.host}`);
  const action = pathname.split('/').pop();

  const supabase = getSupabaseAdmin();

  try {
    if (action === 'login' && req.method === 'POST') {
      const { mobile, password } = req.body;
      if (!mobile || !password) {
        return res.status(400).json({ error: 'Mobile and password are required' });
      }
      const passwordHash = crypto.createHash('sha256').update(password).digest('hex');
      const { data: teacher, error } = await supabase.rpc('check_teacher_login', { 
        p_mobile: mobile, 
        p_password_hash: passwordHash 
      });
      if (error) throw error;
      if (!teacher || teacher.length === 0) {
        return res.status(401).json({ error: 'Invalid mobile number or password' });
      }
      const teacherData = teacher[0];
      await supabase.from('teachers').update({ last_login_at: new Date().toISOString() }).eq('id', teacherData.id);
      return res.status(200).json({ 
        user: {
          id: teacherData.id,
          role: 'teacher',
          name: teacherData.teacher_name,
          institute_id: teacherData.institution_id,
          designation: teacherData.designation,
          photo_url: teacherData.photo_url,
          permissions: teacherData.permissions
        }
      });
    }

    if (action === 'list' && req.method === 'GET') {
      const { institute_id } = req.query;
      if (!institute_id) return res.status(400).json({ error: 'Institute ID is required' });
      const { data: teachers, error } = await supabase.from('teachers').select('*').eq('institution_id', institute_id).order('created_at', { ascending: false });
      if (error) throw error;
      const formattedTeachers = (teachers || []).map(t => ({
        ...t,
        permissions: typeof t.permissions === 'string' ? JSON.parse(t.permissions) : (t.permissions || {})
      }));
      return res.status(200).json({ teachers: formattedTeachers });
    }

    if (action === 'create' && req.method === 'POST') {
      const { institute_id, name, phone, pin, designation, photo_url, permissions } = req.body;
      if (!institute_id || !name || !phone || !pin) return res.status(400).json({ error: 'Required fields missing' });
      const { data: teacher, error: teacherError } = await supabase.from('teachers').insert({
        institution_id: institute_id,
        name,
        phone,
        pin,
        designation,
        photo_url,
        permissions: permissions || {},
        is_active: true
      }).select().single();
      if (teacherError) throw teacherError;
      return res.status(201).json({ success: true, teacher });
    }

    if (action === 'update' && req.method === 'PUT') {
      const { id, name, phone, pin, designation, photo_url, is_active, permissions } = req.body;
      if (!id) return res.status(400).json({ error: 'Teacher ID is required' });
      const updateData: any = { name, phone, designation, photo_url, is_active, permissions };
      if (pin) updateData.pin = pin;
      const { error: teacherError } = await supabase.from('teachers').update(updateData).eq('id', id);
      if (teacherError) throw teacherError;
      return res.status(200).json({ success: true });
    }

    if (action === 'delete' && req.method === 'DELETE') {
      const id = req.query.id || req.body?.id;
      if (!id) return res.status(400).json({ error: 'Teacher ID is required' });
      const { error } = await supabase.from('teachers').delete().eq('id', id);
      if (error) throw error;
      return res.status(200).json({ success: true });
    }

    if (action === 'permissions' && req.method === 'POST') {
      const { teacher_id, permissions } = req.body;
      if (!teacher_id || !permissions) return res.status(400).json({ error: 'Teacher ID and permissions are required' });
      const { error } = await supabase.from('teacher_permissions').upsert({ teacher_id, ...permissions });
      if (error) throw error;
      return res.status(200).json({ success: true });
    }

    return res.status(404).json({ error: 'Action not found' });
  } catch (err: any) {
    console.error(`Teachers API error (${action}):`, err);
    res.status(500).json({ 
      error: err.message || err.error_description || 'Internal server error',
      details: err.details || null
    });
  }
}
