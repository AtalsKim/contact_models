function y = gripper_sim(x, u)
% x = [q; v]
% q = [x_disk, y_disk, th_disk, x1_grip, x2_grip, y_grip]

% System parameters
h = 0.02;
mu = [0.3; 0.3; 0.2];
m = 0.1;
r = 0.5;
m_g = 0.8;

M = diag([m m 0.5*m*r^2 m_g m_g 2*m_g]);

% Extract pose and velocity
n = size(x,1);
q = x(1:n/2);
v = x(n/2+1:end);

% Gravitational, external, and other forces
Fext = [0; -9.81*m; 0; u];

% Contact normal distances (gaps)
psi = [q(4) - q(5)
       r - q(6)
       q(6)
       q(4) - (q(1) + r)
       (q(1) - r) - q(5)
       q(2) - r];

% Jacobian for contacts
J = [ 0  0  0  1 -1  0   % finger1(R)-finger2(L)  (limit)
      0  0  0  0  0 -1   % gripper lift height    (limit)
      0  0  0  0  0  1   % gripper lower height   (limit)
     -1  0  0  1  0  0   % finger1-disk  (contact normal)
      1  0  0  0 -1  0   % finger2-disk  (contact normal)
      0  1  0  0  0  0   % disk-floor    (contact normal)
      0 -1 -r  0  0  1   % finger1-disk (contact tangent)
      0  1 -r  0  0 -1   % finger2-disk (contact tangent)
     -1  0 -r  0  0  0]; % disk-floor   (contact tangent)

% Next pose if contact forces are all zero
q2 = q + h*(v + M\Fext*h);
psi2 = [q2(4) - q2(5)
       r - q2(6)
       q2(6)
       q2(4) - (q2(1) + r)
       (q2(1) - r) - q2(5)
       q2(2) - r];

% Active limits and contacts
l_active = psi2(1:3) < 0.1;
c_active = psi2(4:6) < 0.1;
J = J([l_active; c_active; c_active],:);
psi = psi([l_active; c_active]);
mu = mu(c_active);

% Solve contact dynamics
[q_next, v_next] = forward_lcp(h, M, q, v, Fext, mu, psi, J);
y = [q_next; v_next];
end