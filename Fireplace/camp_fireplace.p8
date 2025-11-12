pico-8 cartridge // http://www.pico-8.com
version 43
__lua__
-- pico-8 axe man prototype 
 -- sprites used: 
 -- player idle base: 1 
 -- player walk step: 2 (loops with 1) 
 -- axe held (idle/walk): 3 
 -- axe swing attack: 4 
 -- tree sprite: 5 
 -- log sprite: 6 
 -- bag sprite: 7 
 -- fireplace sprite: 8 
 -- fire animation sprites: 9, 10 
 -- rabbit sprite: 11 (new)
 -- raw meat sprite: 12 (new)
 -- cooked meat sprite: 13 (new)
 
 -- global constants 
 map_w = 16  
 map_h = 16  
 grass_tile_id = 15     -- tile 15 is used for grass 
 tree_spr_id = 5        -- sprite 5 is the tree 
 log_spr_id = 6         -- sprite 6 is the log 
 bag_spr_id = 7         -- sprite 7 is the bag 
 fireplace_spr_id = 8   -- sprite 8 is the fireplace 
 fire_anim_start = 9    -- fire animation sprites start (9, 10)
 rabbit_spr_id = 11     -- sprite 11 is the rabbit 
 raw_meat_spr_id = 12   -- sprite 12 is raw meat 
 cooked_meat_spr_id = 13-- sprite 13 is cooked meat 
 meat_particle_color = 11 -- color 11 (green/lime) for 'eat' effect 
 
 -- player state variables 
 x = 50 -- player start position 
 y = 50 -- player start position 
 dx = 1           
 state = "idle"     
 equipped_item = "axe"  
 holding_item = nil     -- tracks the item the player is bare-hand holding ("log", "raw_meat", etc.) 
 walk_anim_timer = 0 
 attack_timer = 0   
 attack_duration = 10  
 walk_speed = 1.0    
 
 -- fog and safe zone state variables 
 fp_cx = 64 
 fp_cy = 64 
 safe_radius = 28 
 current_fog_level = 2 -- 0 (clear) to 2 (darkest) 
 
 -- inventory and dynamic object lists 
 inventory = {}           
 trees = {}               
 drops = {}               -- holds all droppable items (logs, raw_meat, cooked_meat)
 rabbits = {}             -- new list for rabbit enemies
 fireplaces = {}          
 fire_particles = {}      
 meat_particles = {}      -- new list for 'eat' effect particles
 circ_anim_timer = 0 
 
 -- --- helper functions --- 
 
 -- note: spr_outline function removed as requested.
 
 -- counts a specific item type in the inventory (for hud)
 function count_item_in_inventory(item_type)
  local count = 0
  for item in all(inventory) do
    if item == item_type then count += 1 end
  end
  return count
 end
 
 -- creates a short-duration green particle effect when the player eats cooked meat
 function spawn_eat_particles(px, py)
  local num_particles = 10
  local duration = 60 -- approx 1 second
  for i = 1, num_particles do
    add(meat_particles, {
      x = px + 2 + rnd(4),
      y = py + 4,
      vx = (rnd(2) - 1) * 0.5, -- slight horizontal drift
      vy = -1 - rnd(1.0),      -- strong upward velocity
      life = duration + rnd(30),
      color = meat_particle_color
    })
  end
  sfx(7) -- eat sfx placeholder
 end
 
 -- creates a generic droppable item (log, raw_meat, cooked_meat)
 function create_drop(item_type, spawn_x, spawn_y)
  local spr_id
  if item_type == "log" then spr_id = log_spr_id
  elseif item_type == "raw_meat" then spr_id = raw_meat_spr_id
  elseif item_type == "cooked_meat" then spr_id = cooked_meat_spr_id
  end
 
  add(drops, {
    x = spawn_x, 
    y = spawn_y, 
    item_type = item_type,
    spr = spr_id, 
    consumed = false,
    vx = 0, vy = 0, gravity = 0, floor_y = 0 -- default physics props 
  })
 end
 
 -- spawns multiple drops (e.g., logs from trees, meat from rabbits)
 function spawn_drops(type_str, parent_x, parent_y, num) 
  local spawned_items_in_event = {} 
  local num_drops = num or (type_str == "log" and 2 + flr(rnd(2)) or 1)
   
  for i = 1, num_drops do 
    local spawn_x, spawn_y 
    local placed = false 
    local attempts = 0 
    local max_attempts = 10 
 
    while not placed and attempts < max_attempts do 
      attempts += 1 
      
      spawn_x = parent_x + rnd(16) - 8 
      spawn_y = parent_y + rnd(16) - 8 
      
      local overlaps = false 
      for existing_item in all(spawned_items_in_event) do 
        if spawn_x < existing_item.x + 8 and 
          spawn_x + 8 > existing_item.x and 
          spawn_y < existing_item.y + 8 and 
          spawn_y + 8 > existing_item.y then 
          overlaps = true 
          break 
        end 
      end 
 
      if not overlaps then 
        placed = true 
      end 
    end 
 
    if placed then 
      create_drop(type_str, spawn_x, spawn_y)
      add(spawned_items_in_event, {x=spawn_x, y=spawn_y}) 
    end 
  end 
 end 
 
 -- destroy tree and spawn logs
 function destroy_tree(tree) 
  del(trees, tree) 
  spawn_drops("log", tree.x, tree.y)
 end 
 
 -- destroy rabbit and spawn raw meat
 function destroy_rabbit(rabbit)
  del(rabbits, rabbit)
  spawn_drops("raw_meat", rabbit.x, rabbit.y, 1) -- rabbits drop 1 raw meat
 end
 
 -- updates the fog and safe zone variables based on the highest fireplace level 
 function get_safe_zone_info() 
  -- ... (no change)
  local max_fp_level = 0 
   
  -- 1. find the highest level of any lit fireplace 
  for fp in all(fireplaces) do 
    if fp.lit and fp.level > max_fp_level then 
      max_fp_level = fp.level 
    end 
  end 
   
  -- 2. use the first fireplace's position as the center of the safe zone 
  if #fireplaces > 0 then 
    fp_cx = fireplaces[1].x + 4 
    fp_cy = fireplaces[1].y + 4 
  end 
 
  -- 3. determine fog level (0=clear, 1=medium, 2=darkest) 
  current_fog_level = 2 - max_fp_level 
  if current_fog_level < 0 then current_fog_level = 0 end 
 
  -- 4. determine collision radius (the wall) 
  safe_radius = 30 -- default (level 0 fireplace / fog level 2) 
  if max_fp_level == 1 then 
    safe_radius = 55 -- level 1 fireplace / fog level 1 (collidable) 
  elseif max_fp_level == 2 then 
    safe_radius = 150 -- level 2 fireplace / fog level 0 (full map access - increased boundary) 
  end 
 end 
 
 
 function check_collision(px, py) 
  -- 1. check collision with trees 
  for tree in all(trees) do 
    if px < tree.x + tree.w and 
      px + 8 > tree.x and 
      py < tree.y + tree.h and 
      py + 8 > tree.y then 
      return true  
    end 
  end 
  
  -- 2. check collision with rabbits (new: treated as solid)
  for rabbit in all(rabbits) do
    if px < rabbit.x + rabbit.w and
      px + 8 > rabbit.x and
      py < rabbit.y + rabbit.h and
      py + 8 > rabbit.y then
      return true
    end
  end
   
  -- 3. check collision with fireplaces 
  for fp in all(fireplaces) do 
    if px < fp.x + fp.w and 
      px + 8 > fp.x and 
      py < fp.y + fp.h and 
      py + 8 > fp.y then 
      return true 
    end 
  end 
   
  -- 4. check collision with fog wall 
  local px_center = px + 4 
  local py_center = py + 4 
  local dist_sq = (px_center - fp_cx)^2 + (py_center - fp_cy)^2 
   
  -- collision occurs if distance from the fireplace center is greater than the current safe radius 
  if dist_sq > safe_radius^2 then 
    return true -- player cannot walk past the fog wall 
  end 
   
  return false 
 end 
 
 function check_attack_hit() 
  if equipped_item ~= "axe" then return false end 
  if state ~= "attack" then return false end 
   
  local axe_w = 8 
  local axe_h = 8 
  local axe_offset_x = dx * 4  
  local axe_offset_y = -1 
  local ax = x + axe_offset_x 
  local ay = y + axe_offset_y 
 
  local hit = false 
  
  -- check trees 
  for tree in all(trees) do 
    if ax < tree.x + tree.w and 
      ax + axe_w > tree.x and 
      ay < tree.y + tree.h and 
      ay + axe_h > tree.y then 
       
      tree.hp -= 1 
      tree.shake = dx  
      tree.shake_timer = 5  
      sfx(0)  
       
      if tree.hp <= 0 then 
        destroy_tree(tree) 
      end 
      hit = true 
    end 
  end 
  
  -- check rabbits (new)
  for rabbit in all(rabbits) do 
    if ax < rabbit.x + rabbit.w and 
      ax + axe_w > rabbit.x and 
      ay < rabbit.y + rabbit.h and 
      ay + axe_h > rabbit.y then 
       
      rabbit.hp -= 1 
      rabbit.shake = dx  
      rabbit.shake_timer = 5  
      sfx(0) 
       
      if rabbit.hp <= 0 then 
        destroy_rabbit(rabbit) 
      end 
      hit = true 
    end 
  end 
  
  return hit 
 end 
 
 -- cycles the equipped tool: axe -> bag -> bare hands -> axe 
 function cycle_tools() 
  if equipped_item == "axe" then 
    equipped_item = "bag" 
  elseif equipped_item == "bag" then 
    equipped_item = "bare_hands"  
  else -- must be "bare_hands" 
    equipped_item = "axe" 
  end 
 end 
 
 -- handles throwing the currently held item (z button action) 
 function throw_item() 
  if holding_item then 
    
    local throw_strength = 3.0 
    local vx = dx * throw_strength 
    local vy = -1.0 
    local floor_y = 100 
    
    add(drops, { -- use 'drops' list
      x = x + (dx * 8), 
      y = y - 4, 
      item_type = holding_item,
      spr = (holding_item == "log" and log_spr_id or (holding_item == "raw_meat" and raw_meat_spr_id or cooked_meat_spr_id)),
      consumed = false,
      vx = vx, 
      vy = vy, 
      gravity = 0.1, 
      floor_y = floor_y 
    }) 
    
    holding_item = nil 
    sfx(9) 
  end 
 end 
 
 -- handles dropping the currently held item (x button action) 
 function drop_held_item() 
  if holding_item then 
    add(drops, { -- use 'drops' list
      x = x + (dx * 8), 
      y = y, 
      item_type = holding_item,
      spr = (holding_item == "log" and log_spr_id or (holding_item == "raw_meat" and raw_meat_spr_id or cooked_meat_spr_id)),
      consumed = false, 
      vx = 0, vy = 0, gravity = 0, floor_y = 0  
    }) 
    holding_item = nil 
    sfx(2)  
    return true 
  end 
  return false 
 end 
 
 -- handles grabbing a log/meat when bare-handed (z button action) 
 function attempt_bare_hands_grab() 
    local interact_x = x + (dx * 8) 
    local interact_y = y 
    local interact_w = 8 
    local interact_h = 8 
    
    local drop_to_interact = nil 
    for drop in all(drops) do 
      -- only interact with drops that are not flying
      if drop.vx == 0 and drop.vy == 0 and interact_x < drop.x + 8 and 
        interact_x + interact_w > drop.x and 
        interact_y < drop.y + 8 and 
        interact_y + interact_h > drop.y then 
        drop_to_interact = drop 
        break 
      end 
    end 
    
    if drop_to_interact then 
      if drop_to_interact.item_type == "cooked_meat" then
        -- eating cooked meat
        del(drops, drop_to_interact)
        spawn_eat_particles(x, y) -- spawn green particles on eat
        return true -- interaction successful (ate meat)
      else
        -- grabbing log or raw meat
        holding_item = drop_to_interact.item_type 
        del(drops, drop_to_interact) 
        sfx(1) -- grab sfx 
        return true 
      end
    end 
    return false 
 end 
 
 -- handles bag interactions (z button action) 
 function check_interaction() 
  if state ~= "interact" then return false end 
 
  -- --- equipped bag (inventory handling / fireplace interaction) --- 
  if equipped_item == "bag" then 
    
    local interact_x = x + (dx * 8) 
    local interact_y = y 
    local interact_w = 8 
    local interact_h = 8 
    
    -- 3a. attempt to pick up any drop (log or meat)
    local drop_to_pickup = nil 
    for drop in all(drops) do 
      if drop.vx == 0 and interact_x < drop.x + 8 and 
        interact_x + interact_w > drop.x and 
        interact_y < drop.y + 8 and 
        interact_y + interact_h > drop.y then 
        drop_to_pickup = drop 
        break 
      end 
    end 
    
    if drop_to_pickup then 
      -- add item_type to inventory (log, raw_meat, cooked_meat)
      add(inventory, drop_to_pickup.item_type) 
      del(drops, drop_to_pickup) 
      sfx(1) 
      return true 
    end 
    
    -- 3b. attempt to interact with fireplace (lighting/feeding with log) 
    local fireplace_to_interact = nil 
    for fp in all(fireplaces) do 
      if interact_x < fp.x + fp.w and 
        interact_x + interact_w > fp.x and 
        interact_y < fp.y + fp.h and 
        interact_y + interact_h > fp.y then 
        fireplace_to_interact = fp 
        break 
      end 
    end 
 
    if fireplace_to_interact then 
      local item_type = inventory[#inventory] 
      
      if #inventory > 0 and item_type == "log" then 
        
        del(inventory, item_type) -- consume the log 
        local amount = 20 
        
        if not fireplace_to_interact.lit then 
          amount = 10 -- initial light 
          fireplace_to_interact.lit = true 
          fireplace_to_interact.level = 1 -- light fire = level 1 
          fireplace_to_interact.range_timer = 1  
          sfx(3)  
        else 
          sfx(4)  
        end 
        
        fireplace_to_interact.fuel += amount 
        if fireplace_to_interact.fuel > fireplace_to_interact.max_fuel then 
          fireplace_to_interact.fuel = fireplace_to_interact.max_fuel 
        end 
        
        return true 
      end 
      -- if any other item type is in the bag (like meat), we don't feed the fire with it.
      return true  
    end 
    
    -- 3c. attempt to drop an item from bag 
    if #inventory > 0 then 
      local item_type = inventory[#inventory] 
      del(inventory, item_type)  
      
      -- create the drop on the ground
      create_drop(item_type, x + (dx * 8), y)
      
      sfx(2)  
      return true 
    end 
  end 
   
  return false  
 end 
 
 -- --- map generation --- 
 function generate_map() 
  for my = 0, map_h - 1 do 
    for mx = 0, map_w - 1 do 
      mset(mx, my, grass_tile_id) 
    end 
  end 
 end 
 
 
 -- --- game initialization --- 
 function _init() 
  x = 50 -- player start position 
  y = 50 -- player start position 
   
  generate_map() 
   
  -- place 3 scattered trees 
  add(trees, { x = 40, y = 72, hp = 5, max_hp = 5, shake = 0, shake_timer = 0, w = 8, h = 8 }) 
  add(trees, { x = 90, y = 30, hp = 5, max_hp = 5, shake = 0, shake_timer = 0, w = 8, h = 8 }) 
  add(trees, { x = 100, y = 100, hp = 5, max_hp = 5, shake = 0, shake_timer = 0, w = 8, h = 8 }) 
 
  -- place 3 scattered rabbits (new)
  for i=1, 3 do
    add(rabbits, {
      x = 10 + rnd(100), 
      y = 10 + rnd(100), 
      hp = 2, -- 20 hp as requested
      max_hp = 2, 
      shake = 0, 
      shake_timer = 0, 
      w = 8, 
      h = 8,
      move_timer = 90, -- moves every 90 frames (3 seconds)
      move_dir = 1 -- 1 for right, -1 for left
    })
  end
 
  -- place fireplace in the center (60, 60) 
  add(fireplaces, { 
    x = 60, 
    y = 60, 
    lit = false, 
    level = 0,               
    fuel = 0,                
    max_fuel = 40,           
    fuel_decay_rate = 1/180, 
    max_radius = 30,         
    range_timer = 0, 
    anim_frame = fire_anim_start,  
    w = 8, 
    h = 8 
  }) 
   
  holding_item = nil -- ensure item holding starts at nil 
 end 
-->8
 -- --- game logic update --- 
 function _update() 
  local ox = x  
  local oy = y  
 
  get_safe_zone_info() -- update fog status and wall boundaries 
 
  -- slower rotation speed 
  circ_anim_timer = (circ_anim_timer + 0.015)  
 
  -- 1. handle tree shake 
  for tree in all(trees) do 
    if tree.shake_timer > 0 then 
      tree.shake_timer -= 1 
      if tree.shake_timer == 0 then 
        tree.shake = 0  
      end 
    end 
  end 
 
  -- 2. handle drop persistence and physics (logs, raw_meat, cooked_meat)
  for drop in all(drops) do
    
    -- apply physics if velocity is non-zero (i.e., item is airborne/thrown)
    if drop.vx ~= 0 or drop.vy ~= 0 then 
      drop.x += drop.vx 
      drop.y += drop.vy 
      drop.vy += drop.gravity 
      
      local drop_hit_fire = false 
      -- check for fireplace collision 
      local drop_w = 8 
      local drop_h = 8 
      for fp in all(fireplaces) do 
        if drop.x < fp.x + fp.w and 
          drop.x + drop_w > fp.x and 
          drop.y < fp.y + fp.h and 
          drop.y + drop_h > fp.y then 
          
          drop_hit_fire = true
          
          if drop.item_type == "log" then
            -- log hit fireplace: feed the fire (consumes log)
            local amount = 20 
            if not fp.lit then 
              amount = 10 
              fp.lit = true 
              fp.level = 1 
              fp.range_timer = 1  
              sfx(3) 
            else 
              sfx(4) 
            end 
            
            fp.fuel += amount 
            if fp.fuel > fp.max_fuel then fp.fuel = fp.max_fuel end 
            drop.consumed = true 
            
          elseif drop.item_type == "raw_meat" and fp.level>0  then
            -- raw meat hit fireplace: cook it (does not consume drop)
            drop.item_type = "cooked_meat"
            drop.spr = cooked_meat_spr_id
            
            -- stop its movement instantly upon cooking/landing
            drop.vx = 0
            drop.vy = 0
            drop.gravity = 0
            drop.floor_y = drop.y + 8 
            
            sfx(10) -- cooking sfx placeholder
            
          else
            -- cooked meat or other items just lands on the fireplace without being consumed
            drop.vx = 0
            drop.vy = 0
            drop.gravity = 0
            drop.floor_y = drop.y + 8 
          end
          
          break -- only hit one fireplace
        end 
      end 
      
      if not drop_hit_fire then 
        -- simple ground check (only if not consumed/cooked)
        if drop.y + 8 > drop.floor_y and drop.vy > 0 then  
            drop.y = drop.floor_y - 8 
            drop.vy = 0 
            drop.gravity = 0 
        end 
        
        -- friction/air resistance 
        if abs(drop.vx) > 0 then 
          drop.vx *= 0.95 
          if abs(drop.vx) < 0.1 then drop.vx = 0 end 
        end 
      end 
    end 
    
    -- delete log only if it was consumed by the fire 
    if drop.consumed then 
      del(drops, drop) 
    end 
  end 
   
  -- 3. handle fireplace logic 
  for fp in all(fireplaces) do 
    if fp.lit then 
      
      -- level up check (l1 -> l2) 
      if fp.level == 1 and fp.fuel >= fp.max_fuel then 
        fp.level = 2 
        fp.max_fuel = 150        
        fp.fuel_decay_rate = 1/240 
        fp.max_radius = 45       
        fp.fuel = fp.max_fuel    
        sfx(6)                   
      end 
      
      -- fuel consumption 
      fp.fuel -= fp.fuel_decay_rate 
      
      if fp.fuel <= 0 then 
        fp.fuel = 0 
        fp.lit = false      
        fp.level = 0        
        fp.range_timer = 0  
        sfx(5)            
      end 
      
      -- safe zone radius animation 
      if fp.range_timer < fp.max_radius then  
        fp.range_timer += 2  
      end 
      
      -- fire sprite animation 
      if flr(circ_anim_timer * 20) % 2 == 0 then  
        fp.anim_frame = fire_anim_start  
      else 
        fp.anim_frame = fire_anim_start + 1 
      end 
 
      -- fire particle spawn logic 
      if flr(rnd(8)) == 0 then  
        add(fire_particles, { 
          x = fp.x + 2 + rnd(4),  
          y = fp.y + 4,  
          vy = -0.5 - rnd(0.5),  
          life = 30 + rnd(30),  
          color = 8 + flr(rnd(2))  
        }) 
      end 
    end 
    -- clamp fuel to max 
    if fp.fuel > fp.max_fuel then fp.fuel = fp.max_fuel end 
  end 
  
  -- 4. handle rabbit movement logic (new)
  for rabbit in all(rabbits) do
    rabbit.move_timer -= 1
    if rabbit.move_timer <= 0 then
      
      rabbit.move_timer = 90 -- reset timer (3 seconds)
      
      -- change direction (left/right only)
      rabbit.move_dir *= -1 
      
      local move_dist = 4
      local new_x = rabbit.x + (rabbit.move_dir * move_dist)
      
      -- simple boundary and collision check 
      if new_x > 0 and new_x < 128 - 8 then
        
        -- check collision with solid objects (trees/fireplaces) at the new position
        local collision = false
        for tree in all(trees) do
          if new_x < tree.x + tree.w and new_x + 8 > tree.x and rabbit.y < tree.y + tree.h and rabbit.y + 8 > tree.y then collision = true break end
        end
        if not collision then
          for fp in all(fireplaces) do
            if new_x < fp.x + fp.w and new_x + 8 > fp.x and rabbit.y < fp.y + fp.h and rabbit.y + 8 > fp.y then collision = true break end
          end
        end
        
        if not collision then
          rabbit.x = new_x
        else
          -- if collision, immediately reverse direction for next time
          rabbit.move_dir *= -1
        end
      else
        -- hit screen edge, immediately reverse direction
        rabbit.move_dir *= -1
      end
    end
    
    -- handle shake when hit
    if rabbit.shake_timer > 0 then 
      rabbit.shake_timer -= 1 
      if rabbit.shake_timer == 0 then 
        rabbit.shake = 0  
      end 
    end 
  end
  
  -- 5. update fire particles movement and lifetime 
  for p in all(fire_particles) do 
    p.y += p.vy 
    p.life -= 1 
    if p.life <= 0 or p.y < 0 then 
      del(fire_particles, p) 
    end 
  end 
 
  -- 6. update meat particles movement and lifetime (new)
  for p in all(meat_particles) do
    p.x += p.vx * 0.5 -- slight horizontal drift
    p.y += p.vy 
    p.life -= 1 
    p.vy += 0.05 -- slight gravity/slowdown
    if p.life <= 0 or p.y < 0 then 
      del(meat_particles, p) 
    end 
  end
  
  -- 7. handle attack/interact state (action lockout) 
  if state == "attack" or state == "interact" then 
    attack_timer -= 1 
    if attack_timer <= 0 then 
      state = "idle" 
    end 
  end 
   
  -- 8. handle item action/switch (x button - button 4) 
  if btnp(4) then 
    if holding_item then 
      -- priority 1: holding item: x drops  
      state = "interact" 
      attack_timer = attack_duration 
      drop_held_item() 
      
    else 
      -- not holding item: x cycles tools (axe, bag, bare hands) 
      cycle_tools() 
    end 
  end 
 
 
  -- 9. handle movement 
  if state ~= "attack" and state ~= "interact" then 
    
    local moving = false 
    local nx = x 
    local ny = y 
    
    if btn(0) then nx -= walk_speed; dx = -1; moving = true end 
    if btn(1) then nx += walk_speed; dx = 1; moving = true end 
    if btn(2) then ny -= walk_speed; moving = true end      
    if btn(3) then ny += walk_speed; moving = true end      
    
    -- check collision with map geometry and fog wall 
    if not check_collision(nx, y) then x = nx end 
    if not check_collision(x, ny) then y = ny end 
    
    moving = (x ~= ox or y ~= oy) 
    
    if moving then 
      state = "walk" 
      walk_anim_timer += 0.2 
    else 
      state = "idle" 
      walk_anim_timer = 0 
    end 
  end 
  
  -- 10. handle action/switch (z button - button 5) 
  if btnp(5) and state ~= "attack" and state ~= "interact" then 
    
    if equipped_item == "bare_hands" then 
      
      if holding_item then 
        -- priority 1: holding item: z throws 
        state = "interact" 
        attack_timer = attack_duration 
        throw_item() 
      else 
        -- bare-handed, not holding: z grabs log/meat/eats cooked meat (action button) 
        state = "interact"  
        attack_timer = attack_duration 
        local success = attempt_bare_hands_grab() 
        if not success then 
          state = "idle"  
          attack_timer = 0 
        end 
      end 
      
    elseif equipped_item == "axe" then 
      state = "attack" 
      attack_timer = attack_duration 
      check_attack_hit() 
      
    else -- equipped_item == "bag" 
      state = "interact" 
      attack_timer = attack_duration 
      check_interaction() -- handles bag interactions (pickup/drop/fireplace) 
    end 
  end 
   
  x = mid(0, x, 128 - 8) 
  y = mid(0, y, 128 - 8) 
 end 
-->8
 -- --- drawing --- 
 function _draw() 
  -- set the base background color based on the current fog level 
  local bg_color = 0 -- black (default) 
   
  -- fireplace level is derived from current_fog_level: 
  if current_fog_level == 0 then 
    bg_color = 3 -- clear background (green) 
  elseif current_fog_level == 1 then 
    bg_color = 1 -- medium fog (dark blue) 
  elseif current_fog_level == 2 then 
    bg_color = 0 -- darkest fog (black) 
  end 
  cls(bg_color)  
 
  -- 1. draw the map (game world) 
  map(0, 0, map_w, map_h, 0, 0)  
 
  -- 2. draw fireplaces, circle, and fire animation 
  for fp in all(fireplaces) do 
    spr(fireplace_spr_id, fp.x, fp.y) 
    
    if fp.lit then 
      -- draw the animated fire sprite on top 
      spr(fp.anim_frame, fp.x, fp.y, 1, 1, false, false) 
      
      -- dotted circle effect (safe zone boundary) 
      local fx = fp.x + 4 
      local fy = fp.y + 4 
      local r = fp.range_timer 
      
      -- draw 48 points (tighter dots) with animation offset 
      for i = 0, 47 do  
        local theta = (i + circ_anim_timer * 4) / 48  
        local cx = fx + cos(theta) * r 
        local cy = fy + sin(theta) * r 
        pset(cx, cy, 7) -- white/light gray dot 
      end 
      
      -- draw fuel bar and level 
      local bar_w = 12  
      local bar_h = 2   
      local bar_x = fp.x - 2 
      local bar_y = fp.y + 10 
      local fuel_percent = fp.fuel / fp.max_fuel 
      local fill_w = flr(bar_w * fuel_percent) 
 
      -- background/empty bar (color 1-dark blue) 
      rectfill(bar_x, bar_y, bar_x + bar_w - 1, bar_y + bar_h - 1, 1) 
      -- fuel fill (color 8-orange/red) 
      rectfill(bar_x, bar_y, bar_x + fill_w - 1, bar_y + bar_h - 1, 8) 
      
      -- display level 
      print("l:"..fp.level, bar_x + bar_w + 1, bar_y, 7) 
    end 
  end 
 
  -- 3. draw fire particles 
  for p in all(fire_particles) do 
    pset(p.x, p.y, p.color) 
  end 
 
  -- 4. draw meat particles (new)
  for p in all(meat_particles) do
    pset(p.x, p.y, p.color)
  end
 
  -- 5. draw trees 
  for tree in all(trees) do 
    local draw_x = tree.x + tree.shake 
    spr(tree_spr_id, draw_x, tree.y) 
  end 
  
  -- 6. draw rabbits and their hp bars if hit (new)
  for rabbit in all(rabbits) do
    local draw_x = rabbit.x + rabbit.shake
    local flip = (rabbit.move_dir == -1) -- flip based on current move direction
    spr(rabbit_spr_id, draw_x, rabbit.y, 1, 1, flip, false)
    
    -- draw hp bar if hit (shake_timer > 0) or low hp
    if rabbit.shake_timer > 0 or rabbit.hp < rabbit.max_hp then
      local bar_w = 8
      local bar_h = 1
      local bar_x = rabbit.x
      local bar_y = rabbit.y - 2
      local hp_percent = rabbit.hp / rabbit.max_hp
      local fill_w = flr(bar_w * hp_percent)

      rectfill(bar_x, bar_y, bar_x + bar_w - 1, bar_y + bar_h - 1, 0) -- background/empty bar (black)
      rectfill(bar_x, bar_y, bar_x + fill_w - 1, bar_y + bar_h - 1, 8) -- hp fill (red/orange)
    end
  end
   
  -- 7. draw drops (logs, raw_meat, cooked_meat) 
  for drop in all(drops) do 
    spr(drop.spr, drop.x, drop.y) 
  end 
 
 
  -- 8. draw player and equipped item (before fog, so they are visible) 
  local flip_x = (dx == -1)  
 
  -- player body 
  local player_spr_id 
  if state == "walk" then 
    local frame = flr(walk_anim_timer) % 2 
    player_spr_id = (frame == 0) and 1 or 2 
  else  
    player_spr_id = 1 
  end 
  spr(player_spr_id, x, y, 1, 1, flip_x, false) 
   
   
  -- equipped item / held item 
  local item_spr_id = -1 
  local item_offset_x = 0  
  local item_offset_y = 0  
  local item_flip_x = flip_x  
 
  if holding_item then -- generic held item (log, meat)
    item_spr_id = (holding_item == "log" and log_spr_id or (holding_item == "raw_meat" and raw_meat_spr_id or cooked_meat_spr_id))
    item_offset_x = dx * 4  
    item_offset_y = -4  
  elseif equipped_item == "axe" then 
    if state == "attack" then 
      item_spr_id = 4  
      item_offset_x = dx * 4  
      item_offset_y = -1 
    else  
      item_spr_id = 3  
      item_offset_x = dx * -6 
      item_offset_y = -1  
    end 
    
  elseif equipped_item == "bag" then 
    item_spr_id = bag_spr_id  
    item_offset_x = dx * 4  
    item_offset_y = 0  
    item_flip_x = false 
    
  elseif equipped_item == "bare_hands" then 
    -- item is bare_hands and not holding anything, so item_spr_id remains -1 
  end 
   
  if item_spr_id ~= -1 then 
    spr(item_spr_id, x + item_offset_x, y + item_offset_y, 1, 1, item_flip_x, false)  
  end 
 
   
  -- 9. draw highly optimized fog mask (square light-of-sight) 
  -- ... (fog drawing logic remains the same)
  local sq_rad_l1 = 45 
  local sq_rad_l2 = 30 
   
  if current_fog_level >= 1 then 
    
    if current_fog_level == 2 then 
      
      local x1_l2 = fp_cx - sq_rad_l2 
      local y1_l2 = fp_cy - sq_rad_l2 
      local x2_l2 = fp_cx + sq_rad_l2 
      local y2_l2 = fp_cy + sq_rad_l2 
      
      local x1_l1 = fp_cx - sq_rad_l1 
      local y1_l1 = fp_cy - sq_rad_l1 
      local x2_l1 = fp_cx + sq_rad_l1 
      local y2_l1 = fp_cy + sq_rad_l1 
      
      local fog_color_1 = 5  
      
      -- a. draw a larger color 5 frame (l1 bounds) 
      -- top 
      rectfill(0, 0, 127, y1_l1 - 1, fog_color_1) 
      -- bottom 
      rectfill(0, y2_l1 + 1, 127, 127, fog_color_1) 
      -- left (only between y1_l1 and y2_l1) 
      rectfill(0, y1_l1, x1_l1 - 1, y2_l1, fog_color_1) 
      -- right (only between y1_l1 and y2_l1) 
      rectfill(x2_l1 + 1, y1_l1, 127, y2_l1, fog_color_1) 
      
      local fog_color_2 = 5  
      
      -- b. draw the color 5 frame (l2 bounds) on top of the color 5 frame. 
      -- top 
      rectfill(0, 0, 127, y1_l2 - 1, fog_color_2) 
      -- bottom 
      rectfill(0, y2_l2 + 1, 127, 127, fog_color_2) 
      -- left (only between y1_l2 and y2_l2) 
      rectfill(0, y1_l2, x1_l2 - 1, y2_l2, fog_color_2) 
      -- right (only between y1_l2 and y2_l2) 
      rectfill(x2_l2 + 1, y1_l2, 127, y2_l2, fog_color_2) 
 
    elseif current_fog_level == 1 then 
      -- fog level 1: color 5 outside r=45, clear square hole inside r=45. 
      local r = sq_rad_l1 
      local x1 = fp_cx - r 
      local y1 = fp_cy - r 
      local x2 = fp_cx + r 
      local y2 = fp_cy + r 
      local fog_color = 5 
 
      -- top 
      rectfill(0, 0, 127, y1 - 1, fog_color) 
      -- bottom 
      rectfill(0, y2 + 1, 127, 127, fog_color) 
      -- left 
      rectfill(0, y1, x1 - 1, y2, fog_color) 
      -- right 
      rectfill(x2 + 1, y1, 127, y2, fog_color) 
      
    end 
  end 
   
 
  -- 10. simple instructions and hud 
  print("state: "..state, 1, 1, 7) 
  print("fog level: "..current_fog_level, 1, 9, 7) 
 
  local item_display = equipped_item 
  if holding_item then item_display = "hands (holding: "..holding_item..")" end 
  print("equipped: "..item_display, 1, 17, 7) 
  
  -- updated hud items (new)
 -- print("logs in bag: "..count_item_in_inventory("log"), 1, 25, 7)
 -- print("raw/cooked meat in bag: "..count_item_in_inventory("raw_meat").."/"..count_item_in_inventory("cooked_meat"), 1, 33, 7)
 -- print("drops on ground: "..#drops, 1, 41, 7)
 -- print("rabbits: "..#rabbits, 1, 49, 7)
   
  -- action prompts 
  if holding_item then 
    -- updated: x now drops, z now throws 
    print("x to drop, z to throw", 1, 120, 7) 
  else 
    if equipped_item == "bare_hands" then 
      print("x to switch, z to grab/eat", 1, 120, 7) -- updated bare-hands prompt
    else 
      print("x to switch, z to use", 1, 120, 7) 
    end 
  end 
 end
__gfx__
000000005555555000000000056d6500000000005b3bbb5055500000000000500000000000000000000000000070007000000000000000000000000000000000
000000005fffff505555555005ddd65000000555b3b3bbb544450000055555150000000000000000000000000070070000000000000000000000000000000000
007007005fffff505fffff5005dddd6500055dd63b3bb3bb494950005111115000000000000a7000000070000077770008eee000024440000000000000000000
000770005f1ff1505fffff5000522dd500522ddd53b33bb5444445000512125000000000000aa00000aaa7000077770008eee70002444f000000000000000000
000770005fffff505f1ff1500052455000542dd605333350544f7500052121500004900000a99a000a8999a0077727e0088e77000224ff000000000000000000
00700700552225505fffff50000554500545dd6500529500054ff5005111111500f44f0000a89a000a9899a00777777000888800002222000000000000000000
0000000005222500552225500000054554556650005245000055500051111115044244f0000aa00000aaaa000777770000000000000000000000000000000000
00000000059595000595595000000054450055000054250000000000051111504422424000000000000000000777770000000000000000000000000000000000
00000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333bb3333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333313333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003333333333333333333b3333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000003333333333b3333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333331bb3333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000033333333333333333333333333b333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333b333333333333333333b3333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000033bb13333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000331333333331b33333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000333333333333333333333333333333330000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33773777377737773777333333333777377337333777333333333333333333333333333333333333333333333333333333333333333333333333333333333333
37333373373733733733337333333373373737333733333333333333333333333333333333333333333333333333333333333333333333333333333333333333
37773373377733733773333333333373373737333773333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33373373373733733733337333333373373737333733333333333333333333333333333333333333333333333333333333333333333333333333333333333333
37733373373733733777333333333777377737773777333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
37773377337733333733377737373777373333333333377733333333333333333333333333333333333333333333333333333333333333333333333333333333
37333737373333333733373337373733373333733333373733333333333333333333333333333333333333333333333333333333333333333333333333333333
37733737373333333733377337373773373333333333373733333333333333333333333333333333333333333333333333333333333333333333333333333333
37333737373733333733373337773733373333733333373733333333333333333333333333333333333333333333333333333333333333333333333333333333
37333773377733333777377733733777377733333333377733333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
37773373373737773777377737773773333333333777373737773333333333333333333333333333333333333333333333333333333333333333333333333333
37333737373733733737373737333737337333333737373737333333333333333333333333333333333333333333333333333333333333333333333333333333
37733737373733733777377737733737333333333777337337733333333733333733337333333333333333333333333333333333333333333333333333333333
37333773373733733733373337333737337333333737373737333733333333333333333333337333333333333333333333333333333333333333333333333333
37773377337737773733373337773777333333333737373737773333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333733333333333333333333333333333333337333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333373333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333337333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333733333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335b3bbb53333333333333333333333333333333
333333333333333333333333333333337333333333333333333333333333333333333333333333333333333333b3b3bbb5333333333333333333333333333333
3333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333b3bb3bb333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333353b33bb5333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333335333353333333333333333333333333333333
33333333333333333333333333337333333333333333333333333333333333333333333333333333333333333333529533333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333524533333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333933333333333333333333333333542533337333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333933333333333333333333333333733373333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333933333333333333333333333333333733733333333333333333333333333333333
33333333333333333333333337333333333333333333333333333333333333333333333333333333333333333333777733333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333777733333333333333333333333333333333
333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333377727e3333337333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333337777773333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333337777733333333333333333333333333333333
33333333333333333333337333333333333333333333333333333333333333333333333333333333333333333337777733333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333373333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333733333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333733733373333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333733733333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333777733333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333777733333333333333
333333333333333333373333333333333333333333333333333333333333338333333333333333333333333333333333333333333333377727e3333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333337777773333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333377777733333333333333
333333333333333333333333333333333356d6533333333333333333333333333333333333333333333333333333333333333333333337777733333333333333
33333333333333333333333333333333335ddd655555553333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333337333333333333335dddd65ffff533333333333333333a7333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333522dd5ffff533333333333333333aa333333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333352455f1ff153333333333333333a99a33333333333333333333333333333333333333333333333333333333333333
3333333333333333333333333333333333335545fffff53333333333333333a89a33333333333333333333333333333333333333333373333333333333333333
333333333333333333333333333333333333335452225533333333333333344aa4f3333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333354222533333333333333344224243333333333333333333333333333333333333333333333333333333333333
33333333333333333337333333333333333333335959533333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333338888888888813773337337773333333333333333333333333373333333333333333333
33333333333333333333333333333333333333333333333333333333338888888888813773377333373333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333777773337773333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333777777337333333333333333333333333333333333333333333333333
3333333333333333333373333333333333333333333333333333333333333333333333377727e337773333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333777777333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333777773333333333333333333333333333333733333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333777773333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333337333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333373333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333373333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333373333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333373333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333337333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333733333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333733333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333373333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333337333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333337333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333373333333333333333333333333333333333733333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333373333333333333333333333733333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333373333733333733333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
37373333377733773333337737373777377733773737333333333777333337773377333337373377377733333333333333333333333333333333333333333333
37373333337337373333373337373373337337333737333333333337333333733737333337373733373333333333333333333333333333333333333333333333
33733333337337373333377737373373337337333777333333333373333333733737333337373777377333333333333333333333333333333333333333333333
37373333337337373333333737773373337337333737337333333733333333733737333337373337373333333333333333333333333333333333333333333333
37373333337337733333377337773777337333773737373333333777333333733773333333773773377733333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333
33333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333333

__map__
1112000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2122000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1314000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
2324000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
