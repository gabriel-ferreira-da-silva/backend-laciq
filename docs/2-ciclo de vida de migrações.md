# criando migração

criando migração, rode o comando na pasta base do projeto

```
php artisan make:migration create_users_table
```

crie a tabela da migração

```
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('users', function (Blueprint $table) {
            $table->id(); // primary key
            $table->string('name');
            $table->string('email')->unique();
            $table->string('password');
            $table->timestamps(); // created_at, updated_at
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('users');
    }
};
```

realize a migração

```
php artisan migrate
```

# modelo

o model é interface entre o php e o banco de dados, ele cria a interface da tabela que o php usará para fazer as alterações

crie o modelo

```
php artisan make:model User
```

exemplo

```
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class User extends Model
{
    protected $fillable = [
        'name',
        'email',
        'password',
        'role',
        'bio',
    ];
}
```

# controller

o controlle define as funções basicas da interface entre laravel e  o banco de dados

cria o controller

``` 
php artisan make:controller UserController
```

exemplo de controller


```
<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    // 📥 Criar usuário
    public function store(Request $request)
    {
        $user = User::create([
            'name' => $request->name,
            'email' => $request->email,
            'password' => Hash::make($request->password),
            'role' => $request->role,
            'bio' => $request->bio,
        ]);

        return response()->json($user);
    }

    // 📤 Listar usuários
    public function index()
    {
        return User::all();
    }

    // 🔍 Buscar um usuário
    public function show($id)
    {
        return User::findOrFail($id);
    }
}
```

# rotas

adicione as rotas

```
<?php

use Illuminate\Support\Facades\Route;
use App\Http\Controllers\UserController;

Route::get('/users', [UserController::class, 'index']);
Route::get('/users/{id}', [UserController::class, 'show']);
Route::post('/users', [UserController::class, 'store']);
```